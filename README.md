# Turn Your Amazon Kindle into a TRMNL

This is a tool to convert your Kindle into a personal dashboard with TRMNL.

<kdb><img src="/images/trmnl-kindle-alpha-release.jpeg" width="650px"></kdb>

As of June 10, 2025 **this is a beta release**. Issues and PRs are welcome. Tested on 10th gen, 12th gen Kindle e-ink displays.

## Prerequisites
- A PC/Mac
- TRMNL [BYOD license](https://shop.usetrmnl.com/products/byod) **or** [BYOD/S client](https://docs.usetrmnl.com/go/diy/byod-s). No* purchase necessary.
- Registered Kindle (5th gen or later)
- Kindle connected to WiFi

`*` - for a 100% free DIY approach, modify our `TRMNL_KINDLE` Zip (Step 19 below) to point to your own server.

## Jailbreak

See [JAILBREAK.md](/JAILBREAK.md) for instructions.

## Install TRMNL

### 1. Set your device model to Kindle
(Skip this step if using a BYOS server and do not have a TRMNL account)

Inside TRMNL visit your BYOD device settings via the top-right > gear cog icon.
Select your Kindle edition in the Device Model dropdown.

![image](https://github.com/user-attachments/assets/6ed0560b-c74b-4d05-ad82-06c07afd8cf3)

### 2. Download TRMNL KUAL Package
Download your TRMNL KUAL package. Log into usetrmnl.com and find your Device ID
by navigating to the top-right dropdown > clicking a device. Your Device ID will
be in the URL, e.g. `1234`.

Next, construct this URL and visit in a new tab:
```
https://usetrmnl.com/devices/<device-id>/kindle/TRMNL_KINDLE.zip
```

This will download a file, `TRMNL_KINDLE_<date>.zip`.

If you do not have a TRMNL account with BYOD license, you can instead try the
[zip_example](/zip_example)
contents and point the URL to your BYOS setup.

### 3. Unzip TRMNL Package
Do this on your computer.

### 4. Create a new file in the TRMNL_KINDLE folder apikey.txt
Login to your TRMNL account and grab the API Key associted with your BYOD
license. Edit the `apikey.txt` in the `TRMNL_KINDLE` directory and make sure
that it only has your API Key in it

### 5. Connect Kindle to computer
Connect USB and enter drag/drop mode.

### 6. Copy TRMNL to Kindle
Copy the `TRMNL_KINDLE` folder to Kindle’s `extensions` folder. It may be named
TRMNL_KINDLE_20250415 with a datestamp at the end. 

<kdb><img src="/images/trmnl-kindle-extension.png" width="500px"></kdb>

### 7. Disconnect Kindle
Safely eject (disconnect) your Kindle.

### 8. Open KUAL
Launch KUAL from your Kindle library.

<kdb><img src="/images/kindle-kual-app.jpeg" width="500px"></kdb>

### 9. Start TRMNL
- Press the **TRMNL** button, then select **Start TRMNL**.

<kdb><img src="/images/kual-trmnl-app.jpeg" width="650px"></kdb>

Your Kindle is now successfully running TRMNL!

<kdb><img src="/images/trmnl-kindle-alpha-release.jpeg" width="650px"></kdb>

**Troubleshooting JSON error**
You may see an error, such as `Fetching JSON... error.. Retry in 60s.` This
likely means you are still in Airplane Mode. Disble Airplane Mode, then re-open
KUAL > TRMNL > Start TRMNL.

<kdb><img src="/images/kindle-json-fetch-error.jpeg" width="650px"></kdb>

## Next steps

Our team is working to accommodate multiple Kindle device frame dimensions, open
source more the TRMNL_KINDLE jailbreak logic for easy extension, and handle
Kindle device "sleep" screens + redraws.

Issues and PRs welcome!
