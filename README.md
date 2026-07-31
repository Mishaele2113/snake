# Snake

<img src="res/logo.svg" width="128" height="128" alt="scrcpy" align="right" />

Simple program of snake game.

## Interaction

Control snake direction with `W`, `A`, `S`, `D` and arrow keys.

<img src="demo.gif" width="300" style="image-rendering: pixelated;">

## Build

### Requirements

* `Swift` >= 6.0
* `MacOS` >= 14.0

### Generate logo

```bash
(cd ./res && ./generate_logo.sh)
```

### Compile program and bundle it to installation archive

```bash
./bundle.sh
```

### Run application

Install created `Snake.dmg` or run program directly with

```bash
./Snake.app/Contents/MacOS/snake
```
