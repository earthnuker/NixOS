// TODO: adapt, remove mastodon integration and media file loading
#![feature(exit_status_error, int_roundings)]
use std::{
    collections::{BTreeMap, BTreeSet, HashMap, HashSet, VecDeque},
    io::{BufRead as _, BufReader, BufWriter, Write as _},
    num::NonZeroUsize,
    ops::RangeInclusive,
    path::{Path, PathBuf},
    process::Stdio,
    sync::OnceLock,
    time::{Duration, Instant},
};

use chrono::{Local, TimeZone};
use color_eyre::{
    eyre::{anyhow, bail, Error, OptionExt},
    Result,
};
use crossbeam_channel::{bounded, Receiver, Sender};
use derive_more::Display;
use fs_err as fs;
use fs_err::{File, OpenOptions};
use human_repr::{HumanCount as _, HumanDuration as _, HumanThroughput as _};
use itertools::{izip, Itertools};
use mastodon_async::{
    entities::notification::NotificationType,
    polling_time::PollingTime,
    prelude::{MediaType as AttachmentMediaType, Status},
};
use rand::prelude::*;
use rand_distr::num_traits::Float as _;
use regex::Regex;
use serde::{Deserialize, Serialize};
use serde_aux::prelude::deserialize_number_from_string;
use serde_json::Value;
use thiserror::Error;
use tokio::{
    io::{AsyncBufReadExt, AsyncReadExt as _},
    runtime::Handle,
};
use tracing::{error, info, warn};
use tracing_error::ErrorLayer;
use tracing_subscriber::{
    layer::SubscriberExt as _, util::SubscriberInitExt as _, EnvFilter, Layer,
};
use wait_timeout::ChildExt as _;
use wrapped_cmd::*;

mod wrapped_cmd;

const FFMPEG_IN_ARGS: &[&str] = &[
    "-loglevel",
    "-repeat+level+fatal",
    "-strict",
    "experimental",
    "-err_detect",
    "ignore_err",
    "-bug",
    "trunc",
    "-ec",
    "favor_inter",
];
const FFMPEG_OUT_ARGS: &[&str] = &["-strict", "experimental"];

type GlitchFunc = fn(&Path) -> Result<GlitchResult>;
static CONFIG: OnceLock<Config> = OnceLock::new();
static WORKDIR: OnceLock<PathBuf> = OnceLock::new();

fn make_rng() -> ThreadRng {
    rand::thread_rng()
}

fn tempfile(name: impl AsRef<Path>) -> Result<PathBuf> {
    let path = WORKDIR.get().unwrap();
    if !path.is_dir() {
        fs::create_dir_all(path)?;
    }
    Ok(path.join(name))
}

fn remove_path(path: impl AsRef<Path>) -> Result<()> {
    let path = path.as_ref();
    if path.is_file() {
        fs::remove_file(path)?;
    }
    if path.is_dir() {
        fs::remove_dir_all(path)?;
    };
    Ok(())
}

fn cleanup() -> Result<()> {
    let dir = WORKDIR.get().unwrap();
    remove_path(dir)?;
    fs::create_dir_all(dir)?;
    Ok(())
}

#[derive(Debug)]
enum FilterValueRange {
    Double(RangeInclusive<f64>),
    Int(RangeInclusive<i64>),
    Boolean,
}

#[derive(Debug)]
enum FilterValueType {
    Double,
    Int,
    Boolean,
    String,
}

#[derive(Debug)]
struct FilterParam {
    range: Option<FilterValueRange>,
    values: Vec<String>,
    data_type: FilterValueType,
}

#[derive(Debug)]
struct Filter {
    name: String,
    params: HashMap<String, FilterParam>,
}

#[derive(Debug, Clone, Serialize)]
struct Filters(Vec<String>);

impl std::fmt::Display for Filters {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0.join(","))
    }
}

#[derive(Debug, Display)]
#[display("{numerator}/{denominator}")]
struct Fraction {
    numerator: usize,
    denominator: NonZeroUsize,
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone, Copy, Hash)]
enum ModeId {
    Audio,
    Video,
    Avi,
}

#[derive(Debug, Clone, Serialize)]

enum Mode {
    Audio {
        codec: Codec,
        filters: Filters,
        pix_fmt_in: PixFmt,
        pix_fmt_out: PixFmt,
        data_fmt_in: String,
        data_fmt_out: String,
        skew: (i64, i64),
        channels: i32,
        bitrate: usize,
        sample_rate_in: usize,
        sample_rate_out: usize,
        corruption: i32,
    },
    Avi {
        codec: Codec,
        window: usize,
        pix_fmt: Option<PixFmt>,
    },
    Video {
        codec: Codec,
        frame_prob: f64,
        glitch_prob: f64,
        frame_types: Vec<char>,
        pix_fmt: Option<PixFmt>,
    },
}

impl Mode {
    fn id(&self) -> ModeId {
        match self {
            Mode::Audio { .. } => ModeId::Audio,
            Mode::Avi { .. } => ModeId::Avi,
            Mode::Video { .. } => ModeId::Video,
        }
    }

    fn tag(&self) -> String {
        match self {
            Mode::Audio {
                codec,
                pix_fmt_in,
                pix_fmt_out,
                data_fmt_in,
                data_fmt_out,
                channels,
                bitrate,
                sample_rate_in,
                sample_rate_out,
                corruption,
                ..
            } => format!(
                "audio_{codec}_{pix_fmt_in}_{data_fmt_in}_{sample_rate_in}_{pix_fmt_out}_{data_fmt_out}_{sample_rate_out}_{bitrate}_{channels}_{corruption}",
                codec = codec.name,
                pix_fmt_in = pix_fmt_in.name,
                pix_fmt_out = pix_fmt_out.name,
            ),
            Mode::Avi {
                codec,
                window,
                pix_fmt,
            } => format!(
                "avi_{codec}_{pix_fmt}_{window}",
                codec = codec.name,
                pix_fmt = pix_fmt
                    .as_ref()
                    .map(|f| f.name.as_str())
                    .unwrap_or_else(|| "default")
            ),
            Mode::Video {
                codec,
                frame_types,
                pix_fmt,
                ..
            } => format!(
                "video_{codec}_{frame_types}_{pix_fmt}",
                codec = codec.name,
                frame_types = frame_types.iter().map(|c| {
                    match c {
                        '?' => 'X',
                        c => *c
                    }
                }).collect::<String>(),
                pix_fmt = pix_fmt
                    .as_ref()
                    .map(|f| f.name.as_str())
                    .unwrap_or_else(|| "default")
            ),
        }
    }
}

impl std::fmt::Display for Mode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Mode::Audio {
                codec,
                filters,
                pix_fmt_in,
                pix_fmt_out,
                data_fmt_in,
                data_fmt_out,
                skew,
                channels,
                bitrate,
                sample_rate_in,
                sample_rate_out,
                corruption,
            } => {
                writeln!(f, "Mode: Audio")?;
                writeln!(f, "Codec: {codec}")?;
                writeln!(f, "Bitrate: {}b/s", bitrate.human_count_bare())?;
                if sample_rate_in != sample_rate_out {
                    writeln!(
                        f,
                        "Samplerate: {} -> {}",
                        sample_rate_in.human_count("Hz"),
                        sample_rate_out.human_count("Hz")
                    )?;
                } else {
                    writeln!(f, "Samplerate: {}", sample_rate_in.human_count("Hz"))?;
                }
                writeln!(f, "Channels: {channels}")?;
                if pix_fmt_in != pix_fmt_out {
                    writeln!(f, "Pixel format: {pix_fmt_in} -> {pix_fmt_out}")?;
                } else {
                    writeln!(f, "Pixel format: {pix_fmt_in}")?;
                }
                if data_fmt_in != data_fmt_out {
                    writeln!(f, "Data format: {data_fmt_in} -> {data_fmt_out}")?;
                } else {
                    writeln!(f, "Data format: {data_fmt_in}")?;
                }
                match corruption {
                    0 => (),
                    -1 => {
                        writeln!(f, "Bitstream corruption: random")?;
                    }
                    corruption => {
                        writeln!(f, "Bitstream corruption: 1/{corruption}")?;
                    }
                }
                writeln!(f, "Size skew: {skew:?}")?;
                if !filters.0.is_empty() {
                    write!(f, "Audio filters: {filters}")?;
                } else {
                    write!(f, "Audio filters: <None>")?;
                }
                Ok(())
            }
            Mode::Video {
                codec,
                frame_prob,
                glitch_prob,
                frame_types,
                pix_fmt,
            } => {
                writeln!(f, "Mode: Video")?;
                writeln!(f, "Codec: {codec}")?;
                if let Some(fmt) = pix_fmt {
                    writeln!(f, "Pixel format: {}", fmt.name)?;
                }
                writeln!(f, "Frame types: {}", frame_types.iter().join(", "))?;
                writeln!(f, "Frame probability: {:.2}%", frame_prob * 100.0)?;
                write!(f, "Bit flip probability: {:.2}%", glitch_prob * 100.0)?;
                Ok(())
            }
            Mode::Avi {
                codec,
                window,
                pix_fmt,
            } => {
                writeln!(f, "Mode: AVI Index")?;
                writeln!(f, "Codec: {codec}")?;
                if let Some(fmt) = pix_fmt {
                    writeln!(f, "Pixel format: {}", fmt.name)?;
                }
                write!(f, "Frame window size: {window}")?;
                Ok(())
            }
        }
    }
}

#[derive(Debug, Clone, Serialize)]
struct GlitchResult {
    #[serde(skip)]
    path: PathBuf,
    mode: Mode,
    timestamp: Duration,
    duration: Duration,
    source: MediaInfo,
    elapsed: Duration,
    jitter: f64,
    msad: f64,
    correlation: f64,
    difference: f64,
    temporal_information: f64,
    spatial_information: f64,
}

impl PartialEq for GlitchResult {
    fn eq(&self, other: &Self) -> bool {
        self.path == other.path
    }
}

impl Eq for GlitchResult {}

fn gmean(p: f64, values: &[[f64; 2]]) -> f64 {
    let w_max = values
        .iter()
        .map(|[w, _]| *w)
        .max_by(|a, b| a.total_cmp(b))
        .unwrap_or_default();
    if p == 0.0 {
        let mut w_total = 0.0;
        let mut v_total = 1.0;
        for [w, v] in values {
            let w = w / w_max;
            w_total += w;
            v_total *= v.powf(w);
        }
        return v_total.powf(w_total.recip());
    }
    let mut w_total = 0.0;
    let mut v_total = 0.0;
    for [w, v] in values {
        let w = w / w_max;
        w_total += w;
        v_total += (w * v).powf(p);
    }
    (v_total / w_total).powf(p.recip())
}

impl GlitchResult {
    #[inline(always)]
    fn loss_prc(&self) -> f64 {
        let cfg = CONFIG.get().unwrap();
        self.duration.min(cfg.clip_length).as_secs_f64() / cfg.clip_length.as_secs_f64()
    }

    fn print_score(&self) {
        let length = self.loss_prc();
        let jitter = 1.0 - self.jitter;
        let msad = self.msad;
        let correlation = self.correlation;
        let si = self.spatial_information;
        let ti = self.temporal_information;
        let diff = self.difference;
        let total = self.score() / 100.0;

        info!(length, jitter, msad, correlation, si, ti, diff, total);
    }

    /*
    TI,SI,DL,C,MSAD,D,J=symbols('TI SI DL C MSAD D J')
    info_score=((TI*SI)**0.5)
    loss_factor = 0.5 + DL * 0.5
    comp = [
        (2.0,info_score),
        (2.0,1-abs(C)),
        (1.0,MSAD),
        (1.0,D),
        (1.0,1-J)
    ]
    score = 100 * loss_factor * sum([v**k for k,v in comp]) ** (1/sum(k for k,v in comp))
    */

    fn score(&self) -> f64 {
        //
        let loss = self.loss_prc();
        let info_score = (self.temporal_information * self.spatial_information).sqrt();
        let score_weights = [
            [2.0, info_score],
            [2.0, 1.0 - self.correlation.abs()],
            [1.0, self.msad],
            [1.0, self.difference],
            [1.0, 1.0 - self.jitter],
        ];
        for [_, v] in score_weights {
            if loss * v < (0.1 / 100.0) {
                return 0.0;
            }
        }
        let loss_factor = 0.5 + loss * 0.5;
        100.0 * loss_factor * gmean(0.0, &score_weights)
    }
}

impl std::fmt::Display for GlitchResult {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let loss = 1.0 - self.loss_prc();
        write!(f, "Source: {}", self.source)?;
        if !self.timestamp.is_zero() {
            writeln!(f, " | {}", self.timestamp.human_duration())?;
        } else {
            writeln!(f)?;
        }
        writeln!(f, "{}", self.mode)?;
        write!(
            f,
            "Score: {score:.2}% (SI: {spatial:.2}%, TI: {temporal:.2}%, Diff: {diff:.2}%, MSAD: {msad:.2}%, C: {corr:.2}%, DL: {loss:.2}%, FJ: {jitter:.2}%)",
            score = self.score(),
            spatial = self.spatial_information * 100.0,
            temporal = self.temporal_information * 100.0,
            diff = self.difference * 100.0,
            loss = loss * 100.0,
            corr = self.correlation * 100.0,
            msad = self.msad * 100.0,
            jitter = self.jitter*100.0
        )?;
        Ok(())
    }
}

#[derive(Debug, Error)]
enum FFError {
    #[error("Timed out after {}", .0.human_duration())]
    TimedOut(Duration),
    #[error("ffmpeg error: {0}")]
    FfmpegError(Error),
    #[error(transparent)]
    IOError(#[from] std::io::Error),
    #[error(transparent)]
    Other(#[from] Error),
}

#[derive(Debug, PartialEq, Eq, Hash, Clone, Copy, Serialize)]
enum CodecFlag {
    Decoding,
    Encoding,
    Video,
    Audio,
    Subtitle,
    Data,
    Attachment,
    Intra,
    Lossy,
    Lossless,
}

impl CodecFlag {
    fn get(value: (usize, char)) -> Result<Option<Self>> {
        let res = match value {
            (0, 'D') => Self::Decoding,
            (1, 'E') => Self::Encoding,
            (2, 'A') => Self::Audio,
            (2, 'D') => Self::Data,
            (2, 'S') => Self::Subtitle,
            (2, 'T') => Self::Attachment,
            (2, 'V') => Self::Video,
            (3, 'I') => Self::Intra,
            (4, 'L') => Self::Lossy,
            (5, 'S') => Self::Lossless,
            (_, '.') => return Ok(None),
            _ => bail!("Invalid: {value:?}"),
        };
        Ok(Some(res))
    }
}

#[derive(Deserialize, Debug, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
enum MediaType {
    Subtitle,
    Video,
    Audio,
}

#[derive(Debug, Clone, Display, Serialize)]
#[display("{name}")]
struct Codec {
    name: String,
    encoder: String,
    flags: HashSet<CodecFlag>,
}
impl Codec {
    fn get_pix_fmts(&self) -> Result<Vec<PixFmt>> {
        let pix_fmts = all_pix_fmts()?;
        let mut cmd = Command::new("ffmpeg");
        let cmd = cmd
            .args(["-loglevel", "-repeat+level+fatal"])
            .args(["-h", &format!("encoder={name}", name = self.name)])
            .stderr(Stdio::inherit())
            .stdout(Stdio::piped())
            .stdin(Stdio::inherit());
        let output = cmd.spawn()?.wait_with_output()?;
        output.status.exit_ok()?;
        let output = std::str::from_utf8(&output.stdout)?;
        let mut fmts = vec![];
        for line in output.lines() {
            if line.contains("Supported pixel formats:") {
                fmts = line
                    .split(':')
                    .nth(1)
                    .unwrap()
                    .trim()
                    .split_ascii_whitespace()
                    .collect();
                break;
            }
        }
        Ok(pix_fmts
            .into_iter()
            .filter(|f| fmts.contains(&f.name.as_str()))
            .collect_vec())
    }
}

#[derive(Debug, Clone, Display, PartialEq, Eq, Serialize)]
#[display("{name} ({size} bit(s), {ncomp} component(s))")]
struct PixFmt {
    name: String,
    size: usize,
    ncomp: usize,
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "lowercase")]
struct Frame {
    #[serde(deserialize_with = "deserialize_number_from_string")]
    pkt_pos: usize,
    #[serde(deserialize_with = "deserialize_number_from_string")]
    pkt_size: usize,
    pict_type: char,
    #[serde(deserialize_with = "deserialize_number_from_string")]
    best_effort_timestamp_time: f64,
}

#[allow(dead_code)]
fn get_framerate(path: impl AsRef<Path>) -> Result<(u32, u32)> {
    let mut proc = Command::new("ffprobe")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-select_streams", "v:0"])
        .args(["-show_streams"])
        .args(["-print_format", "json=c=1"])
        .arg(path.as_ref())
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(Stdio::inherit())
        .spawn()?;
    if !proc.wait()?.success() {
        bail!("failed to get frames!");
    }
    let proc_stdout = proc.stdout.take().unwrap_or_else(|| unreachable!());
    let res: Value = serde_json::from_reader(proc_stdout)?;
    let Some(fr) = res
        .get("streams")
        .and_then(|s| s.as_array())
        .and_then(|s| s.first())
        .and_then(|s| s.get("r_frame_rate"))
        .and_then(|s| s.as_str())
    else {
        bail!("Failed to get framerate")
    };
    match fr.split('/').collect_vec().as_slice() {
        &[a, b] => Ok((a.parse()?, b.parse()?)),
        _ => bail!("Invalid framerate"),
    }
}

fn get_size(path: impl AsRef<Path>) -> Result<(i64, i64)> {
    let mut proc = Command::new("ffprobe")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-select_streams", "v:0"])
        .args(["-show_entries", "stream=width,height"])
        .args(["-print_format", "json=c=1"])
        .arg(path.as_ref())
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(Stdio::inherit())
        .spawn()?;
    if !proc.wait()?.success() {
        bail!("failed to get video size!");
    }
    let proc_stdout = proc.stdout.take().unwrap_or_else(|| unreachable!());
    let res: Value = serde_json::from_reader(proc_stdout)?;
    res.get("streams")
        .and_then(|streams| streams.get(0))
        .and_then(|stream| {
            Some((
                stream.get("width")?.as_i64()?,
                stream.get("height")?.as_i64()?,
            ))
        })
        .ok_or_else(|| anyhow!("Failed to get size of first stream!"))
}

fn get_frames(path: impl AsRef<Path>) -> Result<Vec<Frame>> {
    let mut proc = Command::new("ffprobe")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-select_streams", "v:0"])
        .args(["-show_frames"])
        .args(["-print_format", "json=c=1"])
        .arg(path.as_ref())
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(Stdio::inherit())
        .spawn()?;
    let proc_stdout = proc.stdout.take().unwrap_or_else(|| unreachable!());
    let frames: Result<HashMap<String, Vec<Frame>>> =
        serde_json::from_reader(BufReader::new(proc_stdout)).map_err(Into::into);
    if !proc.wait()?.success() {
        bail!("failed to get frames!")
    }
    let frames = frames?.remove("frames").unwrap_or_default();
    Ok(frames)
}

fn all_pix_fmts() -> Result<Vec<PixFmt>> {
    let mut pix_fmts: Vec<PixFmt> = vec![];
    let mut proc = Command::new("ffmpeg")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-pix_fmts"])
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(Stdio::inherit())
        .spawn()?;
    let proc_stdout = proc.stdout.take().unwrap_or_else(|| unreachable!());
    let proc_stdout = BufReader::new(proc_stdout);
    for line in proc_stdout.lines().map_while(Result::ok) {
        let line: Vec<&str> = line.split_whitespace().collect();
        if line.len() >= 2 && line.get(1) != Some(&"=") && line[0].starts_with("IO") {
            let ncomp = line[2].parse()?;
            let size = line[3].parse()?;
            let name = line[1].to_owned();
            pix_fmts.push(PixFmt { name, ncomp, size });
        }
    }
    proc.wait()?.exit_ok()?;
    Ok(pix_fmts)
}

fn pick_pix_fmt(target_size: usize, yuv: &[String]) -> Result<PixFmt> {
    let cfg = CONFIG.get().unwrap();
    let mut rng = make_rng();
    let fmts = all_pix_fmts()?
        .into_iter()
        .filter(|fmt| {
            let is_yuv = fmt.name.starts_with("yu")
                || fmt.name.starts_with("uy")
                || fmt.name.starts_with("vu")
                || fmt.name.starts_with("p4")
                || fmt.name.starts_with("p2")
                || fmt.name.starts_with("p0");
            if is_yuv {
                return yuv.iter().any(|f| fmt.name.starts_with(f));
            }
            target_size == 0 || fmt.size == target_size
        })
        .map(|f| {
            let mut w = 1;
            for (k, v) in &cfg.fmt_weights {
                if f.name.starts_with(k) {
                    w = *v;
                }
            }
            (w, f)
        })
        .collect_vec();
    Ok(fmts.choose_weighted(&mut rng, |(w, _)| *w)?.1.clone())
}

fn pick_codec(codec_flags: &[CodecFlag], inv_codec_flags: &[CodecFlag]) -> Result<Codec> {
    let cfg = CONFIG.get().unwrap();
    let mut codecs: Vec<Codec> = vec![];
    let mut proc = Command::new("ffmpeg")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-codecs"])
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(Stdio::inherit())
        .spawn()?;
    let proc_stdout = proc.stdout.take().unwrap_or_else(|| unreachable!());
    let proc_stdout = BufReader::new(proc_stdout);
    for line in proc_stdout.lines().map_while(Result::ok) {
        if line.contains("Uncompressed") {
            continue;
        }
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 2 && parts.get(1) != Some(&"=") {
            let mut flags: HashSet<CodecFlag> = HashSet::default();
            for val in parts[0].char_indices() {
                flags.extend(CodecFlag::get(val)?);
            }
            let name = parts[1].to_owned();
            let encoders = parts
                .iter()
                .find_position(|&&w| w == "(encoders:")
                .map(|(s, _)| {
                    parts[s + 1..]
                        .iter()
                        .take_while_inclusive(|&&s| !s.ends_with(')'))
                        .map(|&s| s.trim_matches(|c| c == '(' || c == ')').to_owned())
                        .collect::<Vec<_>>()
                })
                .unwrap_or_default();
            if flags.contains(&CodecFlag::Audio)
                && cfg
                    .audio
                    .codec_blacklist
                    .iter()
                    .any(|c| name.starts_with(c))
            {
                continue;
            }
            if flags.contains(&CodecFlag::Video)
                && cfg
                    .video
                    .codec_blacklist
                    .iter()
                    .any(|c| name.starts_with(c))
            {
                continue;
            }
            codecs.push(Codec {
                name: name.clone(),
                encoder: name.clone(),
                flags: flags.clone(),
            });
            for encoder in encoders {
                codecs.push(Codec {
                    name: name.clone(),
                    encoder,
                    flags: flags.clone(),
                })
            }
        }
    }
    proc.wait()?.exit_ok()?;
    codecs.sort_by(|a, b| a.name.as_str().cmp(b.name.as_str()));
    codecs.dedup_by(|a, b| a.name == b.name);
    let mut nedded_flags = HashSet::from([CodecFlag::Encoding, CodecFlag::Decoding]);
    nedded_flags.extend(codec_flags);
    let mut candidates = Vec::new();
    let default_weight = cfg.codec_weights.get("*").copied().unwrap_or(1);
    let inv_codec_flags: HashSet<CodecFlag> = inv_codec_flags.iter().copied().collect();
    for codec in codecs {
        if codec.flags.is_superset(&nedded_flags)
            && codec.flags.intersection(&inv_codec_flags).count() == 0
        {
            let weight = cfg
                .codec_weights
                .get(&codec.name)
                .copied()
                .unwrap_or(default_weight);
            candidates.push((weight, codec));
        }
    }
    let mut rng = make_rng();
    Ok(candidates.choose_weighted(&mut rng, |(w, _)| *w)?.1.clone())
}

fn get_duration(path: impl AsRef<Path>) -> Result<Duration> {
    let mut cmd = Command::new("ffprobe");
    let proc = cmd
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-print_format", "json=c=1"])
        .args(["-show_entries", "format=duration"])
        .arg(path.as_ref())
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(Stdio::inherit());
    let mut cmd = proc.spawn()?;
    let res = cmd.wait()?;
    if !res.success() {
        bail!("failed to get duration!");
    }
    let res: Value = serde_json::from_reader::<_, Value>(
        cmd.stdout.take().ok_or_else(|| anyhow!("No stdout!"))?,
    )?;
    let duration = res
        .get("format")
        .and_then(|f| f.get("duration"))
        .and_then(|f| f.as_str())
        .map(|f| f.parse())
        .transpose()?
        .map(Duration::from_secs_f64)
        .ok_or_else(|| anyhow!("No duration found in video!"))?;
    Ok(duration)
}

#[tracing::instrument(skip_all)]
fn encode_video(
    path: impl AsRef<Path>,
    codec: &Codec,
    pix_fmt: &Option<PixFmt>,
    ext: &str,
) -> Result<(Duration, PathBuf)> {
    let cfg = CONFIG.get().unwrap();
    let [max_w, max_h] = cfg.max_video_size;
    let mut rng = make_rng();
    let duration = get_duration(&path)?;
    let mut start = Duration::ZERO;
    if duration > cfg.clip_length {
        start = rng.gen_range(Duration::ZERO..(duration - cfg.clip_length));
    }
    let out_path = PathBuf::from("glitch_in._").with_extension(ext);
    let out_path = tempfile(out_path.file_name().unwrap())?;
    let pix_fmt_args = pix_fmt
        .as_ref()
        .map(|f| vec!["-pix_fmt", &f.name])
        .unwrap_or_default();
    let pix_fmt_name = match pix_fmt {
        Some(fmt) => fmt.name.as_str(),
        None => "<default>",
    };
    info!(
        "Encoding {} to {} using {} with pixel format: {} -> {}",
        path.as_ref().display(),
        codec.name,
        codec.encoder,
        pix_fmt_name,
        out_path.display()
    );
    let mut cmd = Command::new("ffmpeg");
    let cmd = cmd
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-ss", &start.as_secs_f64().to_string()])
        .args(["-stream_loop", "-1"])
        .arg("-i")
        .arg(path.as_ref())
        .args(["-strict", "experimental"])
        .args(["-t", &cfg.clip_length.as_secs_f64().to_string()])
        .args(["-c:v", &codec.name])
        .args([
            "-vf",
            &format!(
                "scale={max_w}:{max_h}:force_original_aspect_ratio=decrease:force_divisible_by=2"
            ),
        ])
        .args(["-fs", &cfg.max_file_size.to_string()])
        .args(pix_fmt_args)
        .arg("-an")
        .arg("-sn")
        .arg("-dn")
        .arg(&out_path)
        .stderr(Stdio::null())
        .stdout(Stdio::null())
        .stdin(Stdio::inherit());
    let mut proc = cmd.spawn()?;
    if let Some(res) = proc.wait_timeout(cfg.video.max_encoding_time)? {
        if !res.success() {
            std::thread::sleep(Duration::from_secs_f32(0.5));
            fs::remove_file(out_path)?;
            let res = res.exit_ok().unwrap_err();
            bail!(FFError::FfmpegError(anyhow!(res)));
        }
    } else {
        proc.kill()?;
        std::thread::sleep(Duration::from_secs_f32(0.5));
        fs::remove_file(out_path)?;
        bail!(FFError::TimedOut(cfg.video.max_encoding_time));
    }
    Ok((start, out_path))
}

fn glitch_avi(path: impl AsRef<Path>) -> Result<(PathBuf, usize)> {
    use avirus::AVI;
    let mut rng = make_rng();
    let path = path.as_ref();
    let cfg = CONFIG.get().unwrap();
    // let (denominator,numerator) = get_framerate(path)?;
    let mut avi = AVI::new(path.to_str().unwrap())?;
    let mut out_path = path.with_file_name("glitch_out");
    let _ = path.extension().map(|e| out_path.set_extension(e));
    let n_frames = avi.frames.meta.len();
    let frames = avi.frames.meta.drain(..).collect_vec();
    if frames.iter().all(|f| f.is_iframe()) {
        bail!("Video only contains Keyframes!");
    }
    let w = rng.gen_range(cfg.video.min_frame_window..=cfg.video.max_frame_window);
    while avi.frames.meta.len() < n_frames {
        for w in frames.windows(w) {
            avi.frames.meta.extend(w.choose(&mut rng));
        }
    }
    avi.output(out_path.to_str().unwrap())?;
    Ok((out_path, w))
}

#[tracing::instrument(skip_all)]
fn glitch_video(
    path: impl AsRef<Path>,
    frame_prob: f64,
    flip_prob: f64,
    frames: &[Frame],
) -> Result<(PathBuf, Vec<char>)> {
    let mut rng = make_rng();
    let path = path.as_ref();
    let mut new_path = path.with_file_name("glitch_out");
    if let Some(ext) = path.extension() {
        new_path = new_path.with_extension(ext);
    }
    let pict_types = frames
        .iter()
        .map(|f| f.pict_type)
        .unique()
        .collect::<Vec<char>>();
    let num_types = rng.gen_range(1..=pict_types.len());
    let pict_type = pict_types
        .choose_multiple(&mut rng, num_types)
        .copied()
        .collect_vec();

    let frame_types = pict_types.iter().join(", ");
    let new_path = tempfile(new_path.file_name().unwrap())?;
    info!(
        "Glitching: {} -> {} with frame: {:.2}% bitflip: {:.2}%, {frame_types}",
        path.display(),
        new_path.display(),
        frame_prob * 100.0,
        flip_prob * 100.0
    );
    fs::copy(path, &new_path)?;
    let fh = OpenOptions::new().read(true).write(true).open(&new_path)?;
    let mut mm = unsafe { memmap2::MmapMut::map_mut(&fh) }?;
    for frame in frames.iter() {
        if !pict_types.contains(&frame.pict_type) {
            continue;
        }
        if rng.gen_bool(frame_prob) {
            let frame = frame.pkt_pos..(frame.pkt_pos + frame.pkt_size);
            let frame = &mut mm[frame];
            for b in frame.iter_mut() {
                for bit in 0..8 {
                    if rng.gen_bool(flip_prob) {
                        *b ^= 1 << bit;
                    }
                }
            }
        }
    }
    Ok((new_path, pict_type))
}

#[allow(dead_code)]
fn compute_dssim(res: &GlitchResult, mode: SSIMMode) -> Result<f64> {
    let cfg = CONFIG.get().unwrap();
    let mut cmd = Command::new("ffmpeg");
    let orig = res.source.path();
    let glitched: &Path = res.path.as_ref();
    let filt = [
        "[0:v:0]setpts=PTS-STARTPTS,settb=AVTB[v0]",
        "[1:v:0]setpts=PTS-STARTPTS,settb=AVTB[v1]",
        "[v0][v1]scale=rw:rh,ssim,metadata=print:file=-:direct=1",
    ]
    .join(";");
    let cmd = cmd
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-err_detect", "ignore_err"])
        .args(["-bug", "trunc"])
        .args(["-ec", "favor_inter"])
        .args(["-ss", &res.timestamp.as_secs_f64().to_string()])
        .arg("-i")
        .arg(&orig)
        .args(["-strict", "experimental"])
        .arg("-i")
        .arg(glitched)
        .arg("-shortest")
        .args(["-strict", "experimental"])
        .args(["-filter_complex", &filt])
        .args(["-t", &cfg.clip_length.as_secs_f64().to_string()])
        .args(["-f", "null"])
        .arg("-")
        .stdout(Stdio::piped());

    let mut proc = cmd.spawn()?;
    let ffmpeg_log = BufReader::new(proc.stdout.take().unwrap());
    let mut values: HashMap<String, Vec<f64>> = Default::default();
    for line in ffmpeg_log.lines().map_while(Result::ok) {
        if !line.contains("lavfi.ssim.") {
            continue;
        }
        let Some((key, value)) = line
            .split_ascii_whitespace()
            .last()
            .and_then(|c| c.split_once('='))
        else {
            continue;
        };
        let key = key.split('.').last().unwrap_or_default();
        if key == "dB" {
            continue;
        }
        let value: f64 = (1.0 - value.parse::<f64>()?) / 2.0;
        values.entry(key.to_owned()).or_default().push(value);
    }
    proc.wait()?;
    let y = values.remove("Y").unwrap_or_default();
    let u = values.remove("U").unwrap_or_default();
    let v = values.remove("V").unwrap_or_default();
    let all = values.remove("All").unwrap_or_default();

    for (l1, l2) in [y.len(), u.len(), v.len(), all.len()]
        .into_iter()
        .tuple_windows()
    {
        if l1 != l2 {
            bail!("Inconsitent array lengths for SSIM values");
        }
    }

    let res = match mode { 
        SSIMMode::Chroma => u
            .into_iter()
            .zip(v)
            .map(|(a, b)| (a + b) / 2.0)
            .collect_vec(),
        SSIMMode::Luma => y,
        SSIMMode::All => all,
    };
    if res.is_empty() {
        bail!("Video contains no frames!");
    }
    Ok(res.iter().sum::<f64>() / (res.len() as f64))
}

type FrameInfo = BTreeMap<String, BTreeMap<usize, BTreeMap<String, f64>>>;

#[tracing::instrument(skip_all)]
fn get_frame_info(cmd: &mut Command) -> Result<FrameInfo> {
    let mut proc = cmd.stderr(Stdio::piped()).spawn()?;
    let mut frames: FrameInfo = FrameInfo::new();
    let stderr = BufReader::new(proc.stderr.take().unwrap());
    let mut filter_frame = BTreeMap::default();
    let msg_re =
        Regex::new(r#"\[(?<filter>[\w@]+) @ (?:0x)?[0-f]+\] \[(?<level>\w+)\] (?<value>.+)"#)
            .unwrap();
    for line in stderr.lines() {
        let line = line.unwrap();
        let Some(c) = msg_re.captures(&line) else {
            // info!(target: "ffmpeg", "{line}");
            continue;
        };
        let filter = c.name("filter").map(|m| m.as_str());
        let level = c.name("level").map(|m| m.as_str());
        let value = c.name("value").map(|m| m.as_str());
        if level != Some("info") {
            info!(target: "ffmpeg", "{line}");
            continue;
        }
        let Some((filter, _, value)) = izip!(filter, level, value).next() else {
            info!(target: "ffmpeg", "{line}");
            continue;
        };
        if value.starts_with("frame:") {
            if let Some(frame) = value
                .split(|c: char| c.is_whitespace() || c == ':')
                .nth(1)
                .and_then(|f| f.parse::<usize>().ok())
            {
                filter_frame.insert(filter.to_owned(), frame);
            }
            continue;
        }
        let Some((key, value)) = value.split_once('=') else {
            info!(target: "ffmpeg", "{line}");
            continue;
        };
        if key == "timecode" {
            continue;
        }
        let Some(frame) = filter_frame.get(filter).copied() else {
            info!(target: "ffmpeg", "{line}");
            continue;
        };
        frames
            .entry(filter.to_owned())
            .or_default()
            .entry(frame)
            .or_default()
            .insert(
                key.to_owned(),
                value
                    .parse::<f64>()
                    .map_err(|e| anyhow!("Failed to parse {value:?} for {key}: {e}"))?,
            );
    }
    proc.wait()?.exit_ok()?;
    Ok(frames)
}

fn compute_scores(res: &mut GlitchResult, window: usize) -> Result<()> {
    let filtergraph: &[&[&str]] = &[
        &[
            "[0:v:0]setpts=PTS-STARTPTS",
            "settb=AVTB",
            "split=3[orig_1][orig_2][orig_3]",
        ],
        &[
            "[1:v:0]setpts=PTS-STARTPTS",
            "settb=AVTB",
            "split=5[proc_1][proc_2][proc_3][proc_4][proc_5]",
        ],
        &[
            "[proc_1]boxblur=3",
            "tmix=frames=3",
            "sobel=scale=3",
            "signalstats",
            "metadata@stats=print:direct=1",
        ],
        &[
            "[proc_2]tblend=all_mode=grainextract",
            "boxblur=3",
            "tmix=frames=3",
            "sobel=scale=1",
            "signalstats",
            "metadata@tstats=print:direct=1",
        ],
        &[
            "[orig_1][proc_3]scale=rw:rh",
            "blend=all_mode=grainextract",
            "boxblur=3",
            "tmix=frames=3",
            "sobel=scale=3",
            "signalstats",
            "metadata@diff=print:direct=1",
        ],
        &[
            "[orig_2][proc_4]scale=rw:rh",
            "msad",
            "metadata@msad=print:direct=1",
        ],
        &[
            "[orig_3][proc_5]scale=rw:rh",
            "corr",
            "metadata@corr=print:direct=1",
        ],
    ];
    let filt = filtergraph.iter().map(|g| g.join(",")).join(";");
    let mut cmd = Command::new("ffmpeg");
    cmd.args(["-loglevel", "-repeat+level+info"])
        .args(["-strict", "experimental"])
        .args(["-err_detect", "ignore_err"])
        .args(["-bug", "trunc"])
        .args(["-ec", "favor_inter"])
        .args(["-ss", &res.timestamp.as_secs_f64().to_string()])
        .arg("-i")
        .arg(res.source.path())
        .arg("-i")
        .arg(&res.path)
        .args(["-strict", "experimental"])
        .arg("-lavfi")
        .arg(&filt)
        .args(["-f", "null"])
        .arg("-");
    let frame_info = get_frame_info(&mut cmd)?;

    // w_y + 2*w_uv = 1
    // 2*w_uv = w_y/2
    let w_y = 2f64 / 3f64;
    let w_uv = 1f64 / 6f64;

    let yuv_avg = |(y, u, v): (f64, f64, f64)| y * w_y + u * w_uv + v * w_uv;

    let mut corr = vec![];
    let mut diff = vec![];
    let mut tstats = vec![];
    let mut stats = vec![];
    let mut msad = vec![];

    for frame in frame_info
        .get("metadata@corr")
        .iter()
        .flat_map(|m| m.values())
    {
        let y = frame.get("lavfi.corr.corr.Y").copied().unwrap_or_default();
        let u = frame.get("lavfi.corr.corr.U").copied().unwrap_or_default();
        let v = frame.get("lavfi.corr.corr.V").copied().unwrap_or_default();
        corr.push(yuv_avg((y, u, v)));
    }

    for frame in frame_info
        .get("metadata@diff")
        .iter()
        .flat_map(|m| m.values())
    {
        let y = frame
            .get("lavfi.signalstats.YAVG")
            .copied()
            .unwrap_or_default();
        let u = frame
            .get("lavfi.signalstats.UAVG")
            .copied()
            .unwrap_or_default();
        let v = frame
            .get("lavfi.signalstats.VAVG")
            .copied()
            .unwrap_or_default();
        diff.push(yuv_avg((y, u, v)));
    }

    for frame in frame_info
        .get("metadata@tstats")
        .iter()
        .flat_map(|m| m.values())
    {
        let y = frame
            .get("lavfi.signalstats.YAVG")
            .copied()
            .unwrap_or_default();
        let u = frame
            .get("lavfi.signalstats.UAVG")
            .copied()
            .unwrap_or_default();
        let v = frame
            .get("lavfi.signalstats.VAVG")
            .copied()
            .unwrap_or_default();
        tstats.push(yuv_avg((y, u, v)));
    }

    for frame in frame_info
        .get("metadata@stats")
        .iter()
        .flat_map(|m| m.values())
    {
        let y = frame
            .get("lavfi.signalstats.YAVG")
            .copied()
            .unwrap_or_default();
        let u = frame
            .get("lavfi.signalstats.UAVG")
            .copied()
            .unwrap_or_default();
        let v = frame
            .get("lavfi.signalstats.VAVG")
            .copied()
            .unwrap_or_default();
        stats.push(yuv_avg((y, u, v)));
    }

    for frame in frame_info
        .get("metadata@msad")
        .iter()
        .flat_map(|m| m.values())
    {
        let y = frame.get("lavfi.msad.msad.Y").copied().unwrap_or_default();
        let u = frame.get("lavfi.msad.msad.U").copied().unwrap_or_default();
        let v = frame.get("lavfi.msad.msad.V").copied().unwrap_or_default();
        msad.push(yuv_avg((y, u, v)));
    }

    fn mean(data: &[f64]) -> f64 {
        data.iter().sum::<f64>() / (data.len() as f64)
    }

    fn wavg_max(data: &[f64], window: usize) -> f64 {
        data.windows(window)
            .map(mean)
            .max_by(f64::total_cmp)
            .unwrap_or(0.0)
    }

    

    fn wavg_min(data: &[f64], window: usize) -> f64 {
        data.windows(window)
            .map(mean)
            .min_by(f64::total_cmp)
            .unwrap_or(0.0)
    }


    res.difference = wavg_max(&diff, window) / 255.0;
    res.temporal_information = wavg_max(&tstats, window) / 255.0;
    res.spatial_information = wavg_max(&stats, window) / 255.0;
    res.msad = wavg_max(&msad, window);
    res.correlation = mean(&corr);
    Ok(())
}

#[derive(Debug)]
enum SSIMMode {
    Chroma,
    Luma,
    All,
}

#[allow(dead_code)]
fn windowed_dssim(encoded: impl AsRef<Path>, window: usize, mode: SSIMMode) -> Result<f64> {
    let mut cmd = Command::new("ffmpeg");
    let cmd = cmd
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-err_detect", "ignore_err"])
        .args(["-bug", "trunc"])
        .args(["-ec", "favor_inter"])
        .arg("-i")
        .arg(encoded.as_ref())
        .args(["-strict", "experimental"])
        .args([
            "-lavfi",
            "tpad=start=1[delayed],[v:0][delayed]ssim,metadata=print:file=-:direct=1",
        ])
        .args(["-f", "null"])
        .arg("-")
        .stdout(Stdio::piped());
    let mut proc = cmd.spawn()?;
    let ffmpeg_log = BufReader::new(proc.stdout.take().unwrap());
    let mut values: HashMap<String, Vec<f64>> = Default::default();
    for line in ffmpeg_log.lines().map_while(Result::ok) {
        if !line.contains("lavfi.ssim.") {
            continue;
        }
        let Some((key, value)) = line
            .split_ascii_whitespace()
            .last()
            .and_then(|c| c.split_once('='))
        else {
            continue;
        };
        let key = key.split('.').last().unwrap_or_default();
        if key == "dB" {
            continue;
        }
        let value: f64 = (1.0 - value.parse::<f64>()?) / 2.0;
        values.entry(key.to_owned()).or_default().push(value);
    }
    proc.wait()?;
    let y = values.remove("Y").unwrap_or_default();
    let u = values.remove("U").unwrap_or_default();
    let v = values.remove("V").unwrap_or_default();
    let all = values.remove("All").unwrap_or_default();

    for (l1, l2) in [y.len(), u.len(), v.len(), all.len()]
        .into_iter()
        .tuple_windows()
    {
        if l1 != l2 {
            bail!("Inconsitent array lengths for SSIM values");
        }
    }

    let res = match mode {
        SSIMMode::Chroma => u
            .into_iter()
            .zip(v)
            .map(|(a, b)| (a + b) / 2.0)
            .collect_vec(),
        SSIMMode::Luma => y,
        SSIMMode::All => all,
    };
    if res.is_empty() {
        bail!("Video contains no frames!");
    }
    res.windows(window)
        .map(|w| w.iter().sum::<f64>() / (w.len() as f64))
        .max_by(|a, b| a.total_cmp(b))
        .ok_or_else(|| anyhow!("No frames!"))
}

fn encode_masto_pass(
    path: impl AsRef<Path>,
    out_path: impl AsRef<Path>,
    target_bitrate: f64,
    pass: u8,
) -> Result<()> {
    let ow = CONFIG.get().unwrap().out_width;
    let pass_log = tempfile("ffmpeg2pass")?;
    let path = path.as_ref();
    let out_path = out_path.as_ref();
    let mut cmd = Command::new("ffmpeg");
    let mut out_format: &[&'static str] = &[];
    if pass == 1 {
        out_format = &["-f", "null"];
    }
    let cmd = cmd
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-err_detect", "ignore_err"])
        .args(["-bug", "trunc"])
        .args(["-ec", "favor_inter"])
        .arg("-i")
        .arg(path)
        .args(["-map", "0:v"])
        .args(["-strict", "experimental"])
        .args(["-c:v", "libx264"])
        .args(["-preset", "medium"])
        .args(["-b:v", &target_bitrate.to_string()])
        .args(["-pix_fmt", "yuv420p"])
        .args(["-pass", &pass.to_string()])
        .arg("-passlogfile")
        .arg(&pass_log)
        .args(["-vf", &format!("scale={ow}:-2")])
        .arg("-an")
        .arg("-sn")
        .arg("-dn")
        .args(out_format)
        .arg(out_path)
        .stderr(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stdin(Stdio::inherit());
    let res = cmd.spawn()?.wait()?;
    if let Err(err) = res.exit_ok() {
        bail!(FFError::FfmpegError(err.into()));
    }
    Ok(())
}

#[tracing::instrument(skip_all)]
fn encode_masto(path: impl AsRef<Path>) -> Result<PathBuf> {
    let cfg = CONFIG.get().unwrap();
    let out_path = tempfile("final.mp4")?;
    let path = path.as_ref();
    let duration = get_duration(path)?;
    let mut target_bitrate = (((cfg.max_post_size as f64) / duration.as_secs_f64()) * 8.0) * 0.8;
    info!(
        "Encoding: {} -> {}, target filesize: {}",
        path.display(),
        out_path.display(),
        cfg.max_post_size.human_count_bytes()
    );
    let mut file_size = u64::MAX;
    while file_size > cfg.max_post_size {
        info!("Target bitrate: {}", target_bitrate.human_throughput("b"));
        encode_masto_pass(path, &out_path, target_bitrate, 1)?;
        encode_masto_pass(path, &out_path, target_bitrate, 2)?;
        file_size = out_path.metadata()?.len();
        let diff = ((cfg.max_post_size - 1024) as f64) / (file_size as f64); // bias downwards to speed up convergence
        info!("Bitrate difference: {:.2}%", 100.0 / diff);
        target_bitrate *= diff;
    }
    info!("File size: {}", file_size.human_count_bytes());
    Ok(out_path)
}

#[allow(dead_code)]
fn add_metadata(res: &GlitchResult) -> Result<()> {
    let out_path = res.path.with_file_name("baked_meta").with_extension("mp4");
    let metadata = serde_json::to_string(&res)?;
    let mut cmd = Command::new("ffmpeg");
    let cmd = cmd
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .arg("-i")
        .arg(&res.path)
        .args(["-movflags", "use_metadata_tags+faststart"])
        .args(["-metadata", &format!("settings={metadata}")])
        .args(["-c", "copy"])
        .arg(&out_path)
        .stderr(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stdin(Stdio::inherit());
    cmd.spawn()?.wait()?.exit_ok()?;
    fs::rename(out_path, &res.path)?;
    Ok(())
}

fn rand_sample_rate(low: f64, high: f64) -> usize {
    let mut rng = make_rng();

    let low_l = low.log10();
    let high_l = high.log10();

    let r = rng.gen_range(low_l..=high_l);
    10.0.powf(r) as usize
}

#[tracing::instrument(skip_all)]
fn aglitch(path: &Path) -> Result<GlitchResult> {
    let s_u8 = "u8".to_owned();
    let cfg = CONFIG.get().unwrap();
    let mut rng = make_rng();
    let ow = cfg.out_width;
    let codec = pick_codec(&[CodecFlag::Audio], &[])?;
    let (mut w, mut h) = get_size(path)?;
    let pix_fmt_in = pick_pix_fmt(0, &cfg.audio.yuv)?;
    let mut pix_fmt_out = pix_fmt_in.clone();
    if rng.gen_ratio(1, 5) {
        if rng.gen_ratio(1, 5) {
            pix_fmt_out = pick_pix_fmt(0, &cfg.audio.yuv)?;
        } else {
            pix_fmt_out = pick_pix_fmt(pix_fmt_in.size, &cfg.audio.yuv)?;
        }
    }

    let (mut dx, mut dy) = (0, 0);
    let fmt_group = cfg.audio.fmt_groups.keys().choose(&mut rng).unwrap();
    let data_fmt_in = if rng.gen_ratio(1, 5) {
        cfg.audio.fmt_groups[fmt_group].choose(&mut rng).unwrap()
    } else {
        &s_u8
    };

    let mut data_fmt_out = data_fmt_in;
    if rng.gen_ratio(1, 5) {
        let rx = cfg.audio.max_shift.w;
        dx = rng.gen_range(-rx..=rx);
    }
    if rng.gen_ratio(1, 5) {
        let ry = cfg.audio.max_shift.h;
        dy = rng.gen_range(-ry..=ry);
    }
    if rng.gen_ratio(1, 5) {
        data_fmt_out = cfg.audio.fmt_groups[fmt_group].choose(&mut rng).unwrap();
    }

    w += dx;
    h += dy;
    let mut sample_rate: usize =
        rand_sample_rate(cfg.audio.min_sample_rate, cfg.audio.max_sample_rate);
    let brate: Vec<String> = if rng.gen_ratio(1, 2) {
        let brate = rng.gen_range(1..=1000) * 1000;
        vec!["-b:a".to_owned(), brate.to_string()]
    } else {
        vec![]
    };
    let bitrate = match brate.as_slice() {
        [_, bitrate] => bitrate.parse()?,
        _ => 0,
    };
    let mut noise_amt = rng.gen_range(1..=100);
    if rng.gen_ratio(1, 2) {
        noise_amt = -1;
    }

    let bitstream_filter = if rng.gen_ratio(1, 2) {
        vec!["-bsf:a".to_string(), format!("noise=amount={noise_amt}")]
    } else {
        noise_amt = 0;
        vec![]
    };
    let needs_filter = codec.flags.contains(&CodecFlag::Lossless)
        && data_fmt_in == data_fmt_out
        && pix_fmt_in == pix_fmt_out
        && noise_amt == 0;
    let nfilters = if cfg.audio.max_filters != 0 && (needs_filter || rng.gen_ratio(1, 5)) {
        rng.gen_range(1..=cfg.audio.max_filters)
    } else {
        0
    };
    let mut afilter = Vec::with_capacity(nfilters);
    for _ in 0..nfilters {
        let Some(filt) = cfg.audio.filters.choose(&mut rng) else {
            break;
        };
        afilter.push(filt.clone());
    }
    let afilter_str = afilter.join(",");
    let afilter_arg = if afilter_str.is_empty() {
        vec![]
    } else {
        vec!["-af", &afilter_str]
    };
    let mut achannels = rng.gen_range(1..=4);
    let duration = get_duration(path)?;
    let mut start = Duration::ZERO;
    if duration > cfg.clip_length {
        start = rng.gen_range(Duration::ZERO..(duration - cfg.clip_length));
    }

    if codec.encoder.contains("libgsm") {
        sample_rate = 8000;
        achannels = 1;
    }
    let out_path = tempfile("glitch_out.mkv")?;
    info!(
        "Encoding {path} to {codec} using {encoder}, format: {ch}x{br}:({dx},{dy}) {px_in}|{dt_in}->{px_out}|{dt_out} at {sample_rate} with [{filt}] and noise({noise_amt}) -> {out_path}",
        path=path.display(),
        codec=codec.name,
        encoder=codec.encoder,
        br=bitrate.human_count("b/s"),
        ch=achannels,
        dx=dx,
        dy=dy,
        filt=afilter_str,
        px_in=pix_fmt_in.name,
        sample_rate=sample_rate.human_count("Hz"),
        dt_in=data_fmt_in,
        px_out=pix_fmt_out.name,
        dt_out=data_fmt_out,
        out_path=out_path.display()
    );

    let (mut input_w, mut input_h) = (w, h);

    let max_w = cfg.max_video_size[0] as i64;
    let max_h = cfg.max_video_size[1] as i64;

    if input_w > max_w {
        input_h *= max_w;
        input_h /= input_w;
        input_w = max_w;
    } else if input_h > max_h {
        input_w *= max_h;
        input_w /= input_h;
        input_h = max_h;
    };

    let skewed_w = input_w + dx;
    let skewed_h = input_h + dy;

    let mut video_decoder = Command::new("ffmpeg")
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-ss", &start.as_secs_f64().to_string()])
        .args(["-stream_loop", "-1"])
        .arg("-i")
        .arg(path)
        .args(["-strict", "experimental"])
        .args(["-f", "rawvideo"])
        .args(["-pix_fmt", &pix_fmt_in.name])
        .args(["-vf", &format!("scale={input_w}:{input_h}")])
        .arg("-an")
        .arg("-sn")
        .arg("-dn")
        .arg("-")
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(Stdio::inherit())
        .spawn()?;
    let mut audio_encoder = Command::new("ffmpeg")
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-f", data_fmt_in])
        .args(["-ar", &sample_rate.to_string()])
        .args(["-ac", &achannels.to_string()])
        .args(["-i", "-"])
        .args(["-strict", "experimental"])
        .args(afilter_arg)
        .args(["-c:a", &codec.name])
        .args(&bitstream_filter)
        .args(&brate)
        .args(["-f", "matroska"])
        .arg("-")
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(video_decoder.stdout.take().unwrap())
        .spawn()?;
    let mut audio_decoder = Command::new("ffmpeg")
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-f", "matroska"])
        .args(["-i", "-"])
        .args(["-strict", "experimental"])
        .args(["-f", data_fmt_out])
        .args(["-ar", &sample_rate.to_string()])
        .args(["-ac", &achannels.to_string()])
        .arg("-")
        .stderr(Stdio::inherit())
        .stdout(Stdio::piped())
        .stdin(audio_encoder.stdout.take().unwrap())
        .spawn()?;

    let video_encoder = Command::new("ffmpeg")
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-f", "rawvideo"])
        .args(["-pix_fmt", &pix_fmt_out.name])
        .args(["-s", &format!("{skewed_w}x{skewed_h}")])
        .args(["-i", "-"])
        .args(["-t", &cfg.clip_length.as_secs_f64().to_string()])
        .args(["-strict", "experimental"])
        .args(["-pix_fmt", "yuv420p"])
        .args(["-c:v", "libx264"])
        .args(["-preset", "veryfast"])
        .args(["-crf", "17"])
        .args(["-vf", &format!("scale={ow}:-2")])
        .arg("-an")
        .arg(&out_path)
        .stderr(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stdin(audio_decoder.stdout.take().unwrap())
        .spawn()?;
    let mut procs = vec![
        (video_encoder, "Video Encoder", false),
        (audio_decoder, "Audio Decoder", true),
        (audio_encoder, "Audio Encoder", true),
        (video_decoder, "Video Decoder", true),
    ];
    let mut err = Ok(());
    for (proc, label, can_err) in procs.iter_mut() {
        let Some(res) = proc.wait_timeout(cfg.audio.max_encoding_time)? else {
            error!(
                "{label} timed out after {}!",
                cfg.audio.max_encoding_time.human_duration()
            );
            for (mut proc, label, _) in procs {
                drop(proc.stdin.take());
                drop(proc.stdout.take());
                drop(proc.stderr.take());
                if let Err(e) = proc.kill() {
                    error!("Failed to kill {label}: {e}");
                    if let Err(e) = proc.wait() {
                        error!("Failed to wait for {label}: {e}");
                    };
                }
            }
            bail!(FFError::TimedOut(cfg.audio.max_encoding_time));
        };
        if let Err(e) = res.exit_ok() {
            error!("{label} failed: {e}");
            if !*can_err {
                err = Err(FFError::FfmpegError(anyhow!("{label} Error: {e}")));
            }
        }
    }
    err?;
    Ok(GlitchResult {
        source: MediaInfo::None,
        path: out_path,
        timestamp: start,
        duration: Duration::ZERO,
        elapsed: Duration::ZERO,
        spatial_information: f64::NAN,
        temporal_information: f64::NAN,
        msad: f64::NAN,
        correlation: f64::NAN,
        jitter: f64::NAN,
        difference: f64::NAN,
        mode: Mode::Audio {
            codec,
            filters: Filters(afilter),
            pix_fmt_in: pix_fmt_in.clone(),
            pix_fmt_out: pix_fmt_out.clone(),
            data_fmt_in: data_fmt_in.to_string(),
            data_fmt_out: data_fmt_out.to_string(),
            channels: achannels,
            skew: (dx, dy),
            bitrate,
            sample_rate_in: sample_rate,
            sample_rate_out: sample_rate,
            corruption: noise_amt,
        },
    })
}

#[tracing::instrument(skip_all)]
fn bake_video(path: impl AsRef<Path>) -> Result<PathBuf> {
    let cfg = CONFIG.get().unwrap();
    let path = path.as_ref();
    let out_path = path.with_file_name("baked").with_extension("mkv");
    let mut cmd = Command::new("ffmpeg");
    let cmd = cmd
        .arg("-y")
        .args(["-loglevel", "-repeat+level+fatal"])
        .args(["-strict", "experimental"])
        .args(["-err_detect", "ignore_err"])
        .args(["-bug", "trunc"])
        .args(["-ec", "favor_inter"])
        .arg("-i")
        .arg(path)
        .args(["-strict", "experimental"])
        .args(["-c:v", "libx264"])
        .args(["-preset", "ultrafast"])
        .args(["-crf", "15"])
        .args(["-pix_fmt", "yuv420p"])
        .args(["-vf", "setpts=N/FR/TB"])
        .arg("-an")
        .arg("-sn")
        .arg("-dn")
        .arg(&out_path)
        .stderr(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stdin(Stdio::inherit());
    let mut proc = cmd.spawn()?;
    let Some(res) = proc.wait_timeout(cfg.max_bake_time)? else {
        proc.kill();
        bail!(FFError::TimedOut(cfg.max_bake_time))
    };
    if let Err(err) = res.exit_ok() {
        bail!(FFError::FfmpegError(err.into()));
    }
    Ok(out_path)
}

#[tracing::instrument(skip_all)]
fn vglitch(path: &Path) -> Result<GlitchResult> {
    let cfg = CONFIG.get().unwrap();
    let mut rng = make_rng();
    let ext = cfg.video.exts.choose(&mut rng).unwrap();
    loop {
        let codec = pick_codec(&[CodecFlag::Video], &[])?;
        let pix_fmts = codec
            .get_pix_fmts()?
            .into_iter()
            .map(|f| {
                let mut w = 1;
                for (k, v) in &cfg.fmt_weights {
                    if k == "*" || f.name.starts_with(k) {
                        w = *v;
                    }
                }
                (w, f)
            })
            .collect_vec();

        let pix_fmt = if pix_fmts.is_empty() {
            None
        } else {
            Some(pix_fmts.choose_weighted(&mut rng, |(w, _)| *w).cloned()?.1)
        };

        let (timestamp, encoded) = match encode_video(path, &codec, &pix_fmt, ext) {
            Ok(res) => res,
            Err(e) => {
                error!("Encode Error: {e}");
                continue;
            }
        };
        if !encoded.is_file() {
            continue;
        }
        let frames = get_frames(&encoded)?;
        if frames.is_empty() {
            error!("Video contains no frames!");
            continue;
        }
        let glitch_amt = rng.gen_range(0.0..=1.0);
        let frame_prob = rng.gen_range(0.0..=1.0);
        let ext = encoded
            .extension()
            .and_then(|e| e.to_str())
            .map(|s| s.to_owned());
        let is_inter = !codec.flags.contains(&CodecFlag::Intra);
        let glitch_res = if is_inter && ext.as_deref() == Some("avi") {
            glitch_avi(&encoded).map(|(r, w)| (r, None, Some(w)))
        } else {
            glitch_video(&encoded, frame_prob, glitch_amt, &frames).map(|(r, t)| (r, Some(t), None))
        };

        fs::remove_file(&encoded)?;
        let (glitched, frame_type, window) = match glitch_res {
            Ok(res) => res,
            Err(e) => {
                error!("Glitch Error: {e}");
                continue;
            }
        };

        let baked = match bake_video(&glitched) {
            Ok(path) => path,
            Err(e) => {
                error!("Bake error: {e}");
                continue;
            }
        };

        fs::remove_file(&glitched)?;

        let mode = if ext.as_deref() == Some("avi") && is_inter {
            Mode::Avi {
                codec,
                pix_fmt,
                window: window.unwrap(),
            }
        } else {
            Mode::Video {
                codec,
                frame_prob,
                pix_fmt,
                glitch_prob: glitch_amt,
                frame_types: frame_type.unwrap(),
            }
        };
        return Ok(GlitchResult {
            source: MediaInfo::None,
            path: baked,
            timestamp,
            mode,
            duration: Duration::ZERO,
            spatial_information: f64::NAN,
            temporal_information: f64::NAN,
            jitter: f64::NAN,
            msad: f64::NAN,
            correlation: f64::NAN,
            difference: f64::NAN,
            elapsed: Duration::ZERO,
        });
    }
}

#[derive(Debug, Deserialize)]
struct Downtime {
    from: chrono::NaiveTime,
    to: chrono::NaiveTime,
}

#[derive(Debug, Deserialize)]
struct MaxShift {
    w: i64,
    h: i64,
}

#[derive(Debug, Deserialize)]
struct VideoConfig {
    weight: usize,
    min_frame_window: usize,
    max_frame_window: usize,
    exts: Vec<String>,
    #[serde(with = "humantime_serde")]
    max_encoding_time: Duration,
    codec_blacklist: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct AudioConfig {
    weight: usize,
    yuv: Vec<String>,
    max_filters: usize,
    filters: Vec<String>,
    min_sample_rate: f64,
    max_sample_rate: f64,
    max_shift: MaxShift,
    fmt_groups: HashMap<String, Vec<String>>,
    #[serde(with = "humantime_serde")]
    max_encoding_time: Duration,
    codec_blacklist: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct Config {
    #[serde(with = "humantime_serde")]
    interval: Duration,
    downtime: Downtime,
    #[serde(with = "humantime_serde")]
    min_duration: Duration,
    source_weights: HashMap<MediaSource, usize>,
    max_file_size: u64,
    max_video_size: [u64; 2],
    #[serde(with = "humantime_serde")]
    max_bake_time: Duration,
    out_width: u64,
    max_post_size: u64,
    #[serde(with = "humantime_serde")]
    clip_length: Duration,
    exts: Vec<String>,
    roots: Vec<PathBuf>,
    fmt_weights: HashMap<String, u64>,
    codec_weights: HashMap<String, u64>,
    video: VideoConfig,
    audio: AudioConfig,
}

#[derive(Debug, Deserialize, Clone, Copy, Hash, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
enum MediaSource {
    OldPost,
    Youtube,
    Mention,
    LocalPost,
    RandomQueue,
}

impl MediaSource {
    fn min_duration(&self) -> Duration {
        let cfg = CONFIG.get().unwrap();
        match self {
            MediaSource::OldPost | MediaSource::Youtube | MediaSource::RandomQueue => {
                cfg.min_duration
            }
            MediaSource::Mention | MediaSource::LocalPost => Duration::from_secs(10),
        }
    }

    async fn get(&self) -> Result<MediaInfo> {
        match self {
            MediaSource::OldPost => get_old_post().await,
            MediaSource::Youtube => unreachable!(),
            MediaSource::Mention => get_mention_post().await,
            MediaSource::LocalPost => get_local_post().await,
            MediaSource::RandomQueue => Ok(MediaInfo::Random {
                file: PathBuf::default(),
            }),
        }
    }
}

#[derive(Debug, Clone, Serialize, Display)]
enum MediaInfo {
    #[display("<Unknown>")]
    None,
    #[display("Random item from unposted queue")]
    Random { file: PathBuf },
    // #[display("{}", "file.display()")]
    // File { file: PathBuf },
    #[display("Youtube: {id}")]
    Youtube { id: String, file: PathBuf },
    #[display("{url}")]
    Url { url: String, file: PathBuf },
}

impl MediaInfo {
    fn path(&self) -> PathBuf {
        match self {
            MediaInfo::Url { ref file, .. } => file.clone(),
            MediaInfo::Random { ref file, .. } => file.clone(),
            MediaInfo::Youtube { ref file, .. } => file.clone(),
            MediaInfo::None => PathBuf::default(),
        }
    }
}

fn get_media(status: &Status) -> Vec<(String, String, String)> {
    let mut media = vec![];
    for media_attachment in &status.media_attachments {
        if !matches!(
            media_attachment.media_type,
            AttachmentMediaType::Gifv | AttachmentMediaType::Video
        ) {
            continue;
        }
        if let Some(url) = &media_attachment.url {
            media.push((status.id.to_string(), status.uri.clone(), url.clone()));
        }
    }
    media
}

#[tracing::instrument(skip_all)]
async fn get_mention_post() -> Result<MediaInfo> {
    use futures::prelude::*;
    use mastodon_async::{helpers::toml, prelude::*};
    let mut rng = make_rng();
    let mastodon = Mastodon::from(toml::from_file(std::env::var("MASTODON_CONFIG")?)?);
    mastodon.verify_credentials().await?;
    let statuses = mastodon
        .notifications()
        .await?
        .items_iter()
        .filter_map(|notification| {
            if notification.notification_type == NotificationType::Mention {
                return futures::future::ready(notification.status);
            }
            futures::future::ready(None)
        })
        .take(50)
        .collect::<Vec<_>>()
        .await;
    let mut media = vec![];
    for status in statuses.into_iter() {
        if !status.media_attachments.is_empty() {
            media.extend(get_media(&status));
            continue;
        }
        let liked_by = mastodon
            .favourited_by(&status.id)
            .await?
            .items_iter()
            .map(|a| a.id)
            .collect::<Vec<_>>()
            .await;
        let mut prev = mastodon.get_context(&status.id).await?.ancestors;
        prev.push(status);
        for status in prev {
            if !liked_by.contains(&status.account.id) {
                continue;
            }
            media.extend(get_media(&status));
        }
    }
    let (status_id, status_url, media_url) = media
        .choose(&mut rng)
        .cloned()
        .ok_or(anyhow!("No media statuses!"))?;
    let out_path = tempfile("status.mp4")?
        .with_file_name(status_id)
        .with_extension("mp4");
    info!(
        "Downloading video from status: {status_url} to {out_path}",
        out_path = out_path.display()
    );
    let resp = ureq::get(&media_url).call()?;
    let mut outfile = BufWriter::new(File::create(&out_path)?);
    let size = std::io::copy(&mut resp.into_reader(), &mut outfile)?;
    info!("Saved {}", size.human_count_bytes());
    Ok(MediaInfo::Url {
        url: status_url,
        file: out_path,
    })
}

#[derive(Debug, Deserialize)]
struct Mastodon {
    base: String,
    token: String,
}

#[tracing::instrument(skip_all)]
async fn get_local_post() -> Result<MediaInfo> {
    use megalodon::{
        entities::attachment::AttachmentType, megalodon::GetPublicTimelineInputOptions,
    };
    let mut rng = make_rng();
    let cfg: Mastodon = toml::from_str(&fs::read_to_string(std::env::var("MASTODON_CONFIG")?)?)?;
    let client = megalodon::generator(
        megalodon::SNS::Mastodon,
        cfg.base,
        Some(cfg.token),
        Some(String::from("FFGlitch")),
    );
    let me = client.verify_account_credentials().await?.json;
    let mut pool = vec![];
    let mut opts = GetPublicTimelineInputOptions {
        only_media: Some(true),
        limit: Some(u32::MAX),
        max_id: None,
        since_id: None,
        min_id: None,
    };
    while pool.len() < 10 {
        let statuses = client.get_local_timeline(Some(&opts)).await?.json;
        if statuses.is_empty() {
            break;
        }
        for status in statuses {
            if status.account.id == me.id {
                continue;
            }
            for media in status.media_attachments {
                if !matches!(media.r#type, AttachmentType::Gifv | AttachmentType::Video) {
                    continue;
                }
                pool.push((status.id.clone(), status.uri.clone(), media.url.clone()));
            }
            opts.max_id = Some(status.id)
        }
        info!("Got {}/10 local posts", pool.len());
    }

    let (status_id, status_url, media_url) = pool
        .choose(&mut rng)
        .cloned()
        .ok_or(anyhow!("No media statuses!"))?;
    let out_path = tempfile("status.mp4")?
        .with_file_name(status_id)
        .with_extension("mp4");
    info!(
        target: "local_post",
        "Downloading video from status: {status_url} to {out_path}",
        out_path = out_path.display()
    );
    let resp = ureq::get(&media_url).call()?;
    let mut outfile = BufWriter::new(File::create(&out_path)?);
    let size = std::io::copy(&mut resp.into_reader(), &mut outfile)?;
    info!("Saved {}", size.human_count_bytes());
    Ok(MediaInfo::Url {
        url: status_url,
        file: out_path,
    })
}

fn get_youtube_vid() -> Result<MediaInfo> {
    #[derive(Deserialize)]
    struct YoutubeVid {
        id: String,
        path: PathBuf,
    }
    let out = Command::new(std::env::var("PYTHON")?)
        .arg(std::env::var("DL_PY")?)
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()?
        .wait_with_output()?;
    let stderr = String::from_utf8(out.stderr)?;
    let stdout = String::from_utf8(out.stdout)?;
    if !stderr.is_empty() {
        bail!("{stderr}");
    }
    let Some(line) = stdout.lines().last() else {
        bail!("No output!");
    };
    let vid = serde_json::from_str::<YoutubeVid>(line)?;
    Ok(MediaInfo::Youtube {
        id: vid.id,
        file: vid.path,
    })
}

#[tracing::instrument]
fn youtube_generator() -> Receiver<MediaInfo> {
    let (tx, rx) = crossbeam_channel::bounded(10);
    std::thread::spawn(move || loop {
        let vid = match get_youtube_vid() {
            Ok(res) => res,
            Err(err) => {
                error!("Error: {err}");
                std::thread::sleep(Duration::from_secs_f32(3.0));
                continue;
            }
        };
        while tx.is_full() {
            std::thread::sleep(Duration::from_secs(1));
        }
        if let Err(e) = tx.try_send(vid) {
            warn!("Failed to send youtube mediainfo: {e}");
        };
    });
    rx
}

#[tracing::instrument(skip_all)]
async fn get_old_post() -> Result<MediaInfo> {
    use futures::prelude::*;
    use mastodon_async::{helpers::toml, prelude::*};
    let mut rng = make_rng();
    let mastodon = Mastodon::from(toml::from_file(std::env::var("MASTODON_CONFIG")?)?);
    let me = mastodon.verify_credentials().await?;
    let statuses = mastodon
        .statuses(&me.id, StatusesRequest::new().only_media().to_owned())
        .await?
        .items_iter()
        .flat_map(|status| stream::iter(get_media(&status)))
        .take(50)
        .collect::<Vec<_>>()
        .await;
    let (status_id, status_url, media_url) = statuses
        .choose(&mut rng)
        .cloned()
        .ok_or(anyhow!("No media statuses!"))?;
    let out_path = tempfile("status.mp4")?
        .with_file_name(status_id)
        .with_extension("mp4");
    info!(
        target: "old_post",
        "Downloading video from status: {status_url} to {out_path}",
        out_path = out_path.display()
    );
    let resp = ureq::get(&media_url).call()?;
    let mut outfile = BufWriter::new(File::create(&out_path)?);
    let size = std::io::copy(&mut resp.into_reader(), &mut outfile)?;
    info!(target:"old_post","Saved {}", size.human_count_bytes());
    Ok(MediaInfo::Url {
        url: status_url,
        file: out_path,
    })
}

#[tracing::instrument(skip_all)]
async fn post_status(res: &GlitchResult, t_start: Instant) -> Result<()> {
    const CONTENT_WARNING: &str = "may contain flashing lights and/or colors (also check for content warnings regarding the source material)";
    use mastodon_async::{helpers::toml, prelude::*};
    let cfg = CONFIG.get().unwrap();
    let msg = format!("{res}").trim().to_owned();
    let mut stdout = std::io::stdout().lock();
    let mut stderr = std::io::stderr().lock();
    writeln!(stderr, "==========")?;
    writeln!(stderr, "{msg}")?;
    writeln!(stderr, "==========")?;
    drop(stdout);
    drop(stderr);
    if t_start.elapsed() < cfg.interval {
        wait_until_post()?;
    }
    let mastodon = Mastodon::from(toml::from_file(std::env::var("MASTODON_CONFIG")?)?);
    let media = mastodon
        .media(&res.path, Some("A Glitchy video".to_owned()))
        .await?;
    let atachment = mastodon
        .wait_for_processing(media, PollingTime::default())
        .await?;
    let status = StatusBuilder::new()
        .status(msg)
        .sensitive(true)
        .spoiler_text(CONTENT_WARNING)
        .language(mastodon_async::Language::Eng)
        .media_ids([atachment.id])
        .visibility(Visibility::Public)
        .build()?;
    let status = mastodon.new_status(status).await?;
    info!("Posted: {}", status.uri);
    std::fs::remove_file(res.source.path()).ok();
    Ok(())
}

#[tracing::instrument(skip_all)]
async fn make_video(rx: &Receiver<GlitchResult>, yt: &Receiver<MediaInfo>) -> Result<GlitchResult> {
    let t_start = Instant::now();
    let cfg = CONFIG.get().unwrap();
    let mut rng = make_rng();
    let glitch_funcs: &[(GlitchFunc, &'static str, usize)] = &[
        (aglitch, "Audio", cfg.audio.weight),
        (vglitch, "Video", cfg.video.weight),
    ];
    let sources: Vec<(MediaSource, usize)> = cfg
        .source_weights
        .iter()
        .map(|(&a, &b)| (a, b))
        .collect_vec();
    let mut tries: usize = 0;
    let mut source = sources.choose_weighted(&mut rng, |v| v.1)?.0;
    let info = loop {
        if tries > 5 {
            if tries != usize::MAX {
                warn!("Switching source after 5 failures!");
            }
            source = sources.choose_weighted(&mut rng, |v| v.1)?.0;
            tries = 0;
        }
        info!("Using source: {source:?}");

        let src_res = if matches!(source, MediaSource::Youtube) {
            yt.recv_timeout(Duration::from_secs(3)).map_err(Into::into)
        } else {
            source.get().await
        };
        let mut info = match src_res {
            Ok(info) => info,
            Err(err) => {
                let e_msg = err
                    .chain()
                    .skip(1)
                    .fold(format!("{err}"), |acc, msg| format!("{acc}: {msg}"));
                error!("Error getting video: {err}, sleeping for 30 seconds");
                tries += 1;
                std::thread::sleep(Duration::from_secs_f64(30.0));
                continue;
            }
        };
        if let MediaInfo::Random { file } = &mut info {
            let Ok(res) = rx.try_recv() else {
                warn!("No queue entries!");
                tries = usize::MAX;
                continue;
            };
            *file = res.path;
        }
        let duration = get_duration(&info.path())?;
        if duration >= source.min_duration() {
            break info;
        }
        warn!("Video too short: {}", duration.human_duration());
        tries += 1;
    };
    let in_path = info.path();
    tries = 0;
    let (mut func, mut mode_name, _) = glitch_funcs.choose_weighted(&mut rng, |v| v.2)?;
    let res = loop {
        if tries >= 5 {
            warn!("Switching mode after 5 failures!");
            let (new_func, new_mode_name, _) = glitch_funcs.choose_weighted(&mut rng, |v| v.2)?;
            func = *new_func;
            mode_name = *new_mode_name;
        }
        info!("Processing {} in {} mode", in_path.display(), mode_name);

        let res = (func)(&in_path);
        match res {
            Ok(mut res) => {
                if !res.path.is_file()
                    || res.path.metadata().map(|m| m.len()).unwrap_or_default() == 0
                {
                    error!("Output file doesn't exists or is empty!");
                    continue;
                }
                res.source = info.clone();

                let frames = match get_frames(&res.path) {
                    Ok(res) => res,
                    Err(e) => {
                        error!("Error getting frames: {e}");
                        continue;
                    }
                };

                if frames.is_empty() {
                    error!("Video contains no frames!");
                    continue;
                }

                let duration_secs = frames
                    .iter()
                    .map(|v| v.best_effort_timestamp_time)
                    .max_by(|a, b| a.total_cmp(b))
                    .unwrap_or_default();

                res.duration = Duration::from_secs_f64(duration_secs);

                res.jitter = match frame_jitter(&frames) {
                    Ok(jitter) => jitter,
                    Err(e) => {
                        error!("Framerate Jitter Error: {e}");
                        continue;
                    }
                };

                // res.frame_dssim = match windowed_dssim(&res.path, 10, SSIMMode::All) {
                //     Ok(dur) => dur,
                //     Err(e) => {
                //         error!("Frame DSSIM Error: {e}");
                //         continue;
                //     }
                // };

                // res.dssim = match compute_dssim(&res, SSIMMode::All) {
                //     Ok(diff) => diff,
                //     Err(e) => {
                //         error!("DSSIM Error: {e}");
                //         continue;
                //     }
                // };

                if let Err(e) = compute_scores(&mut res, 5) {
                    error!("Scoring Error: {e}");
                    continue;
                }
                res.print_score();

                let masto_vid = match encode_masto(&res.path) {
                    Ok(res) => res,
                    Err(e) => {
                        error!("Masto encoding: {e}");
                        continue;
                    }
                };
                fs::remove_file(&res.path)?;
                res.path = masto_vid;
                if res.path.metadata()?.len() > cfg.max_post_size {
                    fs::remove_file(&res.path)?;
                    error!("Maximum attachment filesize exceeded");
                    continue;
                }
                res.elapsed = t_start.elapsed();
                // add_metadata(&res)?;
                break res;
            }
            Err(err) => {
                error!("{err}");
                tries += 1;
                continue;
            }
        }
    };
    Ok(res)
}

#[allow(dead_code)]
fn frame_jitter(frames: &[Frame]) -> Result<f64> {
    let frame_durations = frames
        .windows(2)
        .map(|w| w[1].best_effort_timestamp_time - w[0].best_effort_timestamp_time)
        .collect_vec();
    let mean_duration = frame_durations.iter().sum::<f64>() / frame_durations.len() as f64;
    let total_duration = frame_durations.iter().sum::<f64>();
    let max_duration = frame_durations
        .iter()
        .copied()
        .max_by(|a, b| a.total_cmp(b))
        .unwrap_or(0.0);
    let d = (max_duration - mean_duration).abs() / total_duration;
    Ok(d)
}

#[tracing::instrument(skip_all)]
fn wait_until_post() -> Result<()> {
    let mut rng = make_rng();
    let cfg = CONFIG.get().unwrap();
    let interval_secs: i64 = cfg.interval.as_secs().try_into()?;
    let now_secs =
        Local::now().timestamp().next_multiple_of(interval_secs) + rng.gen_range(0..=60) * 60;
    let t = Local
        .timestamp_opt(now_secs, 0)
        .single()
        .ok_or_else(|| anyhow!("Failed to get current time!"))?;
    let dt = (t - Local::now()).max(chrono::Duration::zero()).to_std()?;
    info!("Sleeping for {dt} until {t}", dt = dt.human_duration());
    std::thread::sleep(dt);
    info!("Posting at {t}");
    Ok(())
}

fn sleep_time() -> Option<Duration> {
    return None;
    // TODO: diagnose and fix
    let cfg = CONFIG.get().unwrap();
    let now = Local::now().time();
    let in_window = if cfg.downtime.from <= cfg.downtime.to {
        now >= cfg.downtime.from && now <= cfg.downtime.to
    } else {
        now >= cfg.downtime.from || now <= cfg.downtime.to
    };
    if !in_window {
        None
    } else {
        Some((cfg.downtime.to - now).to_std().unwrap_or_default())
    }
}

// TODO: pass Arc<AtomicUsize> for queue size
#[tracing::instrument(skip_all)]
fn generator_task(rt: Handle, tx: Sender<GlitchResult>, rx: Receiver<GlitchResult>) -> Result<()> {
    let cfg = CONFIG.get().unwrap();
    let mut n: u64 = 0;
    cleanup()?;
    tempfile("")?;
    let yt_gen = youtube_generator();
    loop {
        if let Some(sleep_time) = sleep_time() {
            info!(
                "Downtime {from} to {to}! sleeping for {dt}",
                from = cfg.downtime.from,
                to = cfg.downtime.to,
                dt = sleep_time.human_duration()
            );
            std::thread::sleep(sleep_time);
        }
        let video = rt.block_on(async { make_video(&rx, &yt_gen).await });
        let mut video = match video {
            Ok(res) => res,
            Err(e) => {
                error!("Error: {e}");
                continue;
            }
        };
        let mut out_path = PathBuf::from("out");
        fs::create_dir_all(&out_path)?;
        let file_name = format!("{n:03}.mp4");
        out_path.push(&file_name);
        fs::copy(&video.path, &out_path).and_then(|_| fs::remove_file(&video.path))?;
        info!(
            "Saved as {file_name}, took {duration}",
            duration = video.elapsed.human_duration()
        );
        video.path = out_path;
        // fs::write(video.path.with_extension("txt"), format!("{video}"))?;
        cleanup()?;
        tx.send(video)?;
        n += 1;
    }
}

#[tracing::instrument(skip_all)]
fn spawn_generator(rt: Handle) -> Result<(Receiver<GlitchResult>, Sender<GlitchResult>)> {
    let (tx_res, rx_res) = bounded(0);
    let (tx_rec, rx_rec) = bounded(10);
    std::thread::spawn(move || loop {
        let tx_res = tx_res.clone();
        let rx_rec = rx_rec.clone();
        let rt = rt.clone();
        if let Err(e) = generator_task(rt, tx_res, rx_rec) {
            error!("Generator failed ({e}), restarting!");
        }
    });
    Ok((rx_res, tx_rec))
}

fn init_logging() {
    use tracing_subscriber::fmt::time::ChronoLocal;
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::fmt::layer()
                .with_timer(ChronoLocal::new(String::from("%F %X%.3f")))
                .with_filter(EnvFilter::from_default_env()),
        )
        .with(ErrorLayer::default())
        .init();
}

/* TODO:
- add `generate` method to `Mode`
- move `aglich` and `vglitch` into methods of `Mode`
- genetic algorithm for mutation?
- weight codecs and paramters by likes
- persistent state
- Migrate docker image to scratch+musl
*/

#[tokio::main(flavor = "multi_thread")]
async fn main() -> Result<()> {
    init_logging();
    if cfg!(linux) {
        use libc::{signal, SIGCHLD, SIG_IGN};
        unsafe { signal(SIGCHLD, SIG_IGN) };
        info!("Disabled SIGCHLD handling");
    }
    let mut rng = make_rng();
    let mut dummy_buf = VecDeque::new();
    CONFIG
        .set(toml::from_str(&fs::read_to_string(std::env::var(
            "CONFIG_FILE",
        )?)?)?)
        .map_err(|_| anyhow!("Set Config"))?;
    WORKDIR
        .set({
            let dir = std::env::temp_dir().join("ffglitch");
            if dir.exists() {
                fs::remove_dir_all(&dir)?;
                fs::create_dir_all(&dir)?;
            };
            dir
        })
        .map_err(|_| anyhow!("Set Workdir"))?;
    let cfg = CONFIG.get().unwrap();
    let day = Duration::from_secs(60 * 60 * 24);
    // Keep enough posts for 1 day
    let batch_size = (day.as_secs_f64() / cfg.interval.as_secs_f64()).ceil() as usize;
    let (rx, tx) = spawn_generator(Handle::current())?;
    let mut buffers: HashMap<ModeId, VecDeque<GlitchResult>> = HashMap::default();
    let mut t_start = Instant::now();
    // let mut post_idx = 0;
    loop {
        loop {
            let total_len: usize = buffers.values().map(|v| v.len()).sum();
            let sizes: BTreeMap<_, _> = buffers.iter().map(|(k, v)| (k, v.len())).collect();
            info!(
                "Queue size {} ({:?}) of {}",
                total_len,
                sizes,
                batch_size * 2
            );
            if total_len >= (batch_size * 2) {
                break;
            }
            let Ok(res) = rx.recv_timeout(cfg.interval.div_f64(2.0)) else {
                break;
            };
            buffers.entry(res.mode.id()).or_default().push_back(res);
        }
        let buffer = buffers
            .values_mut()
            .choose(&mut rng)
            .unwrap_or(&mut dummy_buf);
        buffer
            .make_contiguous()
            .sort_by(|a, b| a.score().total_cmp(&b.score()));
        let Some(best) = buffer.pop_back() else {
            warn!("Buffer empty, sleeping for 3 seconds before retrying");
            std::thread::sleep(Duration::from_secs(3));
            continue;
        };
        if sleep_time().is_none() {
            if let Some(worst) = buffer.pop_front() {
                info!(
                    "Worst: {:.2}% {} {}",
                    worst.score(),
                    worst.mode.tag(),
                    worst.path.display()
                );
                let path = worst.path.clone();
                if tx.try_send(worst).is_err() {
                    // let _ = fs::remove_file(path.with_extension("txt"));
                    // let _ = fs::remove_file(path.with_extension("json"));
                    fs::remove_file(path)?;
                }
            }
        }

        info!(
            "Best: {:.2}% {} {}",
            best.score(),
            best.mode.tag(),
            best.path.display()
        );
        if let Err(e) = post_status(&best, t_start).await {
            warn!("Error posting status: {e:?}");
        };
        // let saved_file = best.path.with_file_name(format!("{post_idx:04}"));
        // fs::rename(&best.path, saved_file.with_extension("saved.mp4"))?;
        // fs::write(saved_file.with_extension("info.txt"), format!("{best}"))?;
        // let data = serde_json::to_string(&best)?;
        // fs::write(saved_file.with_extension("json"), &data)?;
        // post_idx += 1;
        // if buffer.len() < batch_size {
        //     println!("Sleeping for 5 minutes to allow queue to refill");
        //     std::thread::sleep(Duration::from_secs_f64(300.0));
        // }
        t_start = Instant::now();
        if best.path.exists() {
            let _ = fs::remove_file(&best.path);
        }
    }
}
