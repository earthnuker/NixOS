use std::{io::Read, process::ExitStatus, time::Duration};

use tracing::{debug, error, info, warn};
pub(crate) struct WrappedCommand(std::process::Command);
pub(crate) struct WrappedChild(std::process::Child);

pub(crate) type Command = WrappedCommand;
pub(crate) type Child = WrappedChild;

// impl std::ops::Deref for WrappedCommand {
//     type Target = std::process::Command;

//     fn deref(&self) -> &Self::Target {
//         &self.0
//     }
// }

// impl std::ops::DerefMut for WrappedCommand {
//     fn deref_mut(&mut self) -> &mut Self::Target {
//         &mut self.0
//     }
// }

impl WrappedCommand {
    pub fn new<S: AsRef<std::ffi::OsStr>>(program: S) -> Self {
        Self(std::process::Command::new(program))
    }

    pub fn spawn(&mut self) -> std::io::Result<WrappedChild> {
        self.0.spawn().map(|p| WrappedChild(p))
    }

    pub fn arg<S: AsRef<std::ffi::OsStr>>(&mut self, arg: S) -> &mut Self {
        self.0.arg(arg);
        self
    }

    pub fn args<I, S>(&mut self, args: I) -> &mut Self
    where
        I: IntoIterator<Item = S>,
        S: AsRef<std::ffi::OsStr>,
    {
        self.0.args(args);
        self
    }

    pub fn stderr<T: Into<std::process::Stdio>>(&mut self, cfg: T) -> &mut Self {
        self.0.stderr(cfg);
        self
    }

    pub fn stdin<T: Into<std::process::Stdio>>(&mut self, cfg: T) -> &mut Self {
        self.0.stdin(cfg);
        self
    }

    pub fn stdout<T: Into<std::process::Stdio>>(&mut self, cfg: T) -> &mut Self {
        self.0.stdout(cfg);
        self
    }
}

impl WrappedChild {
    pub fn wait_with_output(mut self) -> std::io::Result<std::process::Output> {
        let status = self.0.wait()?;
        let mut stdout = Vec::new();
        let mut stderr = Vec::new();
        if let Some(mut h_stdout) = self.0.stdout.take() {
            h_stdout.read_to_end(&mut stdout)?;
        }
        if let Some(mut h_stderr) = self.0.stderr.take() {
            h_stderr.read_to_end(&mut stderr)?;
        }
        return Ok(std::process::Output {
            stdout,
            stderr,
            status,
        });
    }

    pub fn kill(&mut self) -> std::io::Result<()> {
        self.0.kill()
    }

    pub fn wait(&mut self) -> std::io::Result<std::process::ExitStatus> {
        self.0.wait()
    }
}

impl wait_timeout::ChildExt for WrappedChild {
    fn wait_timeout(&mut self, dur: Duration) -> std::io::Result<Option<std::process::ExitStatus>> {
        self.0.wait_timeout(dur)
    }
}

impl std::ops::Deref for WrappedChild {
    type Target = std::process::Child;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

impl std::ops::DerefMut for WrappedChild {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.0
    }
}

impl Drop for WrappedChild {
    fn drop(&mut self) {
        let proc = &mut self.0;
        let pid = proc.id();
        debug!("Dropping PID {pid}");
        drop(proc.stdin.take());
        drop(proc.stdout.take());
        drop(proc.stderr.take());
        match proc.try_wait() {
            Ok(Some(_)) => {}
            Ok(None) => {
                info!("Killing {pid}: {res:?}", res = self.kill());
                info!("Waiting for {pid}: {res:?}", res = self.wait());
            }
            Err(e) => {
                error!("Error while waiting on child process: {}", e);
            }
        }
    }
}
