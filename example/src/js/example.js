import { Camera } from '@capacitor/camera'
import { Capacitor } from '@capacitor/core'
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';
import { FilePicker } from '@capawesome/capacitor-file-picker';
import { CapacitorVideoCompress } from 'capacitor-video-compress';

const base64ToBlob = (b64Data, contentType, sliceSize = 512) => {
    const byteCharacters = atob(b64Data)
    const byteArrays = []
      
    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
        const slice = byteCharacters.slice(offset, offset + sliceSize)
      
        const byteNumbers = new Array(slice.length)
        // eslint-disable-next-line no-plusplus
        for (let i = 0; i < slice.length; i++) {
            byteNumbers[i] = slice.charCodeAt(i)
        }
      
        const byteArray = new Uint8Array(byteNumbers)
        byteArrays.push(byteArray)
    }
      
    return new Blob(byteArrays, { type: contentType })
}

window.compressVideo = async () => {
    if (Capacitor.isNativePlatform()) {
        const { photos: photosPermissions } = await Camera.checkPermissions()
        console.log('perms_photos', photosPermissions)

        if (photosPermissions !== 'granted') {
            const { photos: newPhotosPermissions } = await Camera.requestPermissions({ permissions: ['photos'] })
            if (newPhotosPermissions !== 'granted' && newPhotosPermissions !== 'limited') {
                alert('Permission to read photos denied')
                return []
            }
        }
    }

    const { files: result } = await FilePicker.pickVideos({
        limit: 1,
    })

    console.log('result', result)

    const path = result[0].path

    try {
        const timeStart = new Date().getTime()
        const { compressedUri } = await CapacitorVideoCompress.compressVideo({ fileUri: path })
        console.log('compressedUri', compressedUri)

        const readFileResult = await Filesystem.readFile({
            path: compressedUri.split('/').pop(), // android
            // path: compressedUri, // ios
            directory: Directory.Data
        })

        console.log('readFileResult', readFileResult)

        // const blob = base64ToBlob(readFileResult.data,'video/mp4') 
        // console.log('blob', blob)

        const fileWriteRes = await Filesystem.writeFile({
            path: `compressedvideo-${new Date().toISOString().substring(11)}.mp4`,
            data: readFileResult.data,
            directory: Directory.Library,
            encoding: Encoding.UTF8,
            });
        console.log('file write result', fileWriteRes)

        alert(`Compress finished in ${(new Date().getTime() - timeStart) / 1000}s`)
    } catch (e) {
        console.error('An error occurred', e.message)
        alert(`An error occurred: ${e.message}`)
    }
}
