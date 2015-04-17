# RemoteTwain
Remote use of TWAIN-compatible scanner

RemoteTWAIN allows you to use any TWAIN-compliant scanner over the network. The program consists of two parts.
Server part runs on a computer that is connected to the scanner. Client part runs on any computer on the network,
and as the address of the scanner used the network address of the computer running the server RemoteTwain.
Client receive from the server list of available scanners and their settings, can change the scan settings and picture taking.
The resulting images can be saved in a file (supported formats include PNG, JPG, BMP), the clipboard or send to the printer.

The default data format is Memory, capable of receiving data from the scanner to the RAW format. This mode allows you to use
all features of the scanner, but it requires large amount of memory to run. With some scanners, this mode may not work correctly.

Native format uses a Windows RGB Bitmap image transmission. The size and number of colors of the transmitted image is limited.

Some scanners have ability to save images in various file formats. At the same time, the quality and image parameters in the
file entirely dependent on the scanner driver. Client receives a complete picture file, preview is not available in this case.
Received file will be saved in the selected folder.
