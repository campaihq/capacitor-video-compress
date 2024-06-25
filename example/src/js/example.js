import { CapacitorVideoCompress } from 'capacitor-video-compress';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    CapacitorVideoCompress.echo({ value: inputValue })
}
