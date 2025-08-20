# Time Management 

Time Management 

This guide explains how to install `clickable`, build the `TimeManagement` project, and run it on both desktop and Ubuntu Touch devices.

## Prerequisites

- Ubuntu or Debian-based system
- Git
- Python 3
- Docker (for cross-compilation and device builds)

## Install Clickable

Follow the official steps to install `clickable`:

```bash
# Install required dependencies
sudo apt update
sudo apt install git python3 python3-pip

# Install Clickable using pip
pip3 install --user clickable-ut

# Add Clickable to your PATH
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

Verify installation:

```bash
clickable --version
```


## Build the project
To build the project, clone this repo and then you can run 

```bash
clickable desktop 
```

The above command will run the project on desktop

```bash
clickable install
```
to install the app on the connected device.

## License

/*
 * MIT License
 *
 * Copyright (c) 2025 CIT-Services
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 


References
* https://clickable-ut.dev/en/latest/
* Location of DB : ~/.clickable/home/.local/share/ubtms/Databases

