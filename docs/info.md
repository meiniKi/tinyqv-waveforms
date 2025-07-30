<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

The peripheral index is the number TinyQV will use to select your peripheral.  You will pick a free
slot when raising the pull request against the main TinyQV repository, and can fill this in then.  You
also need to set this value as the PERIPHERAL_NUM in your test script.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# TinyQV Waveforms

Author: Meinhard Kissich

Peripheral index: 

## What it does

TODO

## Register map

Document the registers that are used to interact with your peripheral

| Address | Name   | Access | Description                                                 |
| ------- | ------ | ------ | ----------------------------------------------------------- |
| 0x00    | DATA   | W      | Byte of binary logic-level data; 8 sequential states        |
| 0x01    | SPI    | W      | Byte of SPI data to tunnel to the display                   |
| 0x02    | CONF   | W      | Set of config data: CS, DC, prescaler[3:0]                  |
| 0x08    | SEL    | W      | Select the signal track to update                           |
| 0x8     | STATUS | R      | Indicator if the peripheral is ready (0x01), or busy (0x00) |
|         |        |        |                                                             |

## How to test

TODO

## External hardware

SSD1306 or compatible (SPI).