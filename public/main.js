var flags = null

// Start our Elm application
var app = Elm.Main.init({ flags: flags })

app.ports.initializeCamera.subscribe(initializeCamera(app))

let freezeFrame = false
const loadQRLib = () => {
    if (typeof window.jsQR !== typeof undefined) {
        return Promise.resolve()
    }
    freezeFrame = false
    return new Promise((resolve, reject) => {
        const script = document.createElement('script')
        script.type = 'text/javascript'
        script.onload = resolve
        script.onerror = reject
        document.getElementsByTagName('head')[0].appendChild(script)
        script.src = "public/jsQR.min.js"
        // script.src = "https://cdn.jsdelivr.net/npm/jsqr@1.0.4/dist/jsQR.min.js"

    })
}
const Colors = {
    darkGreen: "#61A591",
    purple: "#594fee",
    errorRed: "#c80000",
    tealGreen: "#00b2c3",
}

stopMessages = false
function initializeCamera(app) {
    return () => {
        sleep(500)
            .then(loadQRLib)
            .then(() => {
                app.ports.disableCamera.subscribe((after) => {
                    stopMessages = true
                    sleep(after).then(() => { stopCamera(app) })
                })

                app.ports.setFrameFrozen.subscribe((isFrozen) => {
                    setFrameFrozen(isFrozen)
                })

                const canvasEl = document.getElementById('camera-canvas')
                if (!(canvasEl instanceof HTMLCanvasElement)) {
                    return
                }
                canvasElement = canvasEl
                const canvasObj = canvasElement.getContext("2d");
                if (!(canvasObj instanceof CanvasRenderingContext2D)) {
                    return
                }
                canvas = canvasObj
                video = document.createElement("video");

                // Use facingMode: environment to attemt to get the front camera on phones
                navigator.mediaDevices
                    .getUserMedia({ video: true})
                    .then((stream) => {
                        if (video) {

                            video.srcObject = stream;
                            video.setAttribute("playsinline", "true"); // required to tell iOS safari we don't want fullscreen
                            video.play();
                            app.ports.receiveCameraActive.send(true)
                            sleep(20000).then(() => { stopCamera(app) })
                            requestAnimationFrame(tick);
                        }

                    })
                    .catch((e) => {

                        if (e.message.match("not found")) {
                            app.ports.noCameraFoundError.send(true)
                        }
                        app.ports.receiveCameraActive.send(false)
                    })

                function tick() {
                    if (!video) {
                        return
                    }

                    if (freezeFrame) {
                        sleep(0).then(() => { requestAnimationFrame(tick) });
                        return
                    }

                    if (video.readyState === video.HAVE_ENOUGH_DATA) {
                        if (!canvasElement || !canvas) {
                            return
                        }

                        canvasElement.height = video.videoHeight;
                        canvasElement.width = video.videoWidth;
                        canvas.drawImage(video, 0, 0, canvasElement.width, canvasElement.height);
                        var imageData = canvas.getImageData(
                            0,
                            0,
                            canvasElement.width,
                            canvasElement.height
                        );
                        const jsQR = window.jsQR
                        if (jsQR) {

                            var code = jsQR(imageData.data, imageData.width, imageData.height, { inversionAttempts: 'dontInvert' });
                            if (code && code.data !== "") {
                                drawBox(
                                    code.location.topLeftCorner,
                                    code.location.topRightCorner,
                                    code.location.bottomRightCorner,
                                    code.location.bottomLeftCorner,
                                    Colors.purple
                                );
                                freezeFrame = true;
                                if (!stopMessages) {
                                    app.ports.scannedDeviceCode.send(code.data)
                                }
                            }
                        }
                    }

                    sleep(0).then(() => { requestAnimationFrame(tick) });
                }
            })
            .catch((e) => {
                app.ports.receiveCameraActive.send(false)
            })
    }
}



function drawBox(begin, b, c, d, color) {
    if (!canvas) { return }
    canvas.beginPath();
    canvas.moveTo(begin.x, begin.y);
    canvas.lineTo(b.x, b.y);
    canvas.lineTo(c.x, c.y);
    canvas.lineTo(d.x, d.y);
    canvas.lineTo(begin.x, begin.y);
    canvas.lineWidth = 4;
    canvas.strokeStyle = color;
    canvas.stroke();
}

function stopCamera(app) {
    if (!video || !canvasElement || !canvas) {
        return
    }


    var stream = video.srcObject
    if (stream instanceof MediaStream) {

        stream.getTracks().forEach(track => {
            track.stop()
        })
    }


    video.srcObject = null
    video.pause()

    app.ports.receiveCameraActive.send(false)
    canvas.clearRect(0, 0, canvasElement.width, canvasElement.height);

    canvasElement.height = 0;
    canvasElement.width = 0;

    canvas = null
    canvasElement = null
    video = null
}

function sleep(time) {
    return new Promise((resolve) => setTimeout(resolve, time))
}

function setFrameFrozen(isFrozen) {
    freezeFrame = isFrozen
}

app.ports.rerouteTo.subscribe((url) => {
    console.log(url)
    window.open(url, "_blank")
})
