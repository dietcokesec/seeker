# `compile_shell`
It's really simple. You want to run a C executable in an environment with an older (or newer) version of glibc than you. Right now this is ubuntu only. Note that you must have a working `Makefile` in the target directory
## Example
```bash
# General
./compile_shell <directory-of-c-code> <glibc-target>

# Practical example
./compile_shell /home/kali/Desktop/Kali/Tools/CVE-2021-3156/ 2.31
```

# `attachments`
All things attached to the linux system line disks, users, groups, etc.
## Example
```bash
# That's it!
./attachments
```

# `versions`
All version-related data associated with a linux system.
## Example
```bash
# That's it!
./versions
```
