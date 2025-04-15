{config, ...}: [
  {
    resources = {
      disk = "/mnt/data";
      label = "Storage";
    };
  }
  {
    resources = {
      disk = "/";
      cpu = true;
      memory = true;
      label = "System";
    };
  }
]
