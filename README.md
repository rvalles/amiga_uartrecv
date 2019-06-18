Fast, polled serial port file transfer to Amiga.
Currently hardcoded to 506699 bps on PAL Amiga, which is the maximum I've been able to reach with a FTDI rs232 dongle on the other end.
Works on any Amiga, even with a basic 68000.
Pre-release, not ready for the masses yet.
Receiver assembles on AsmTwo, and probably asmone/vasm and other assemblers.
Sender uses python3, pyserial.
TODO
* Autodetect CLI vs WB.
* Detect stack size, CLI and WB cases, and set buffer size accordingly.
* Set target file via command line parameters.
* Usage docs.
