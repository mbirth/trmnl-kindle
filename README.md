# Turn Your Amazon Kindle into a TRMNL

This is a tool to convert your Kindle into a personal dashboard with TRMNL.

<kdb><img src="/images/trmnl-kindle-alpha-release.jpeg" width="650px"></kdb>

As of June 10, 2025 **this is a beta release**. Issues and PRs are welcome.
Tested on 10th gen, 12th gen Kindle e-ink displays.

> [!IMPORTANT]
> This fork was optimised specifically for a 10th gen Kindle Paperwhite running
> firmware **5.15.1.1**. It may not work properly on other Kindles or 10th gen
> Kindles with a different firmware version.
>
> ![Battery discharge comparison](/images/discharge-curve.png)

## Prerequisites
- A PC/Mac
- TRMNL [BYOD license](https://shop.usetrmnl.com/products/byod) **or**
  [BYOD/S client](https://docs.usetrmnl.com/go/diy/byod-s). No* purchase
  necessary.
- Registered Kindle (5th gen or later)
- Kindle connected to WiFi

`*` - for a 100% free DIY approach, modify our `TRMNL_KINDLE` Zip (Step 19
below) to point to your own server. ([TRMNL BYOS Laravel](https://github.com/usetrmnl/byos_laravel)
is one of the most advanced free servers.)

## Jailbreak

See [JAILBREAK.md](/JAILBREAK.md) for instructions.

For easier debugging, you might also want to install [KOSSH](https://github.com/guo-yong-zhi/KOSSH).

## Install TRMNL

### 1. Set your device model to Kindle
(Skip this step if using a BYOS server and do not have a TRMNL account)

Inside TRMNL visit your BYOD device settings via the top-right > gear cog icon.
Select your Kindle edition in the Device Model dropdown.

![](/images/trmnl-device-model.png)

### 2. Configure your API key
Login to your TRMNL account and grab the API Key associated with your BYOD
license. In the `zip_example` folder, copy the file `TRMNL.conf.example` to
`TRMNL.conf` and edit it. Change the value of `API_KEY` to your API key.

### 3. Connect Kindle to computer
Connect USB and enter drag/drop mode.

### 4. Copy TRMNL to Kindle
On your Kindle, create a new folder `TRMNL_KINDLE` below the `extensions`
folder. Then copy the files from `zip_example` into that newly created folder.

<kdb><img src="/images/trmnl-kindle-extension.png" width="500px"></kdb>

### 5. Disconnect Kindle
Safely eject (disconnect) your Kindle.

### 6. Open KUAL
Launch KUAL from your Kindle library.

<kdb><img src="/images/kindle-kual-app.jpeg" width="500px"></kdb>

### 7. Start TRMNL
- Press the **TRMNL** button, then select **Start TRMNL**.

<kdb><img src="/images/kual-trmnl-app.jpeg" width="650px"></kdb>

Your Kindle is now successfully running TRMNL!

<kdb><img src="/images/trmnl-kindle-alpha-release.jpeg" width="650px"></kdb>

## Troubleshooting

### JSON error
You may see an error, such as `Fetching JSON... error.. Retry in 60s.` This
likely means you are still in Airplane Mode. Disble Airplane Mode, then re-open
KUAL > TRMNL > Start TRMNL.

<kdb><img src="/images/kindle-json-fetch-error.jpeg" width="650px"></kdb>

### Graphic not displayed
The Kindle expects a very specific graphics format. You can convert existing
images using this ImageMagick command:

```bash
magick input.jpg -resize 1448x1072! -set colorspace Gray -define png:bit-depth=8 -define png:color-type=0 -rotate 90 output.png
```
