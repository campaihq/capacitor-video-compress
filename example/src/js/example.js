import { Camera } from '@capacitor/camera';
import { Capacitor } from '@capacitor/core';
import { Media } from '@capacitor-community/media';
import { FilePicker } from '@capawesome/capacitor-file-picker';
import { CapacitorVideoCompress } from 'capacitor-video-compress';

const getMediasAlbumIdentifier = async () => {
  const albumName = 'videoCompress';
  const { albums } = await Media.getAlbums();
  let album = albums.find(a => a.name === albumName);
  if (!album) {
    try {
      await Media.createAlbum({ name: albumName });
    } catch (e) {
      console.error('Creating album', e);
      // on Android, albuns might not be returned by getAlbums so we receive an error
      // when we try to create it again, that's why we ignore it
    }

    const { albums: updatedAlbuns } = await Media.getAlbums();
    album = updatedAlbuns.find(a => a.name === albumName);
  }

  return album?.identifier;
};

const saveVideoToGallery = async fileUri => {
  const albumIdentifier = await getMediasAlbumIdentifier();

  const res = await Media.saveVideo({
    path: fileUri,
    // on Android for safety we use albumName always, in case album was not found
    albumIdentifier,
  });

  return res?.filePath;
};

window.compressVideo = async () => {
  if (Capacitor.isNativePlatform()) {
    const { photos: photosPermissions } = await Camera.checkPermissions();
    console.log('perms_photos', photosPermissions);

    if (photosPermissions !== 'granted') {
      const { photos: newPhotosPermissions } = await Camera.requestPermissions({
        permissions: ['photos'],
      });
      if (
        newPhotosPermissions !== 'granted' &&
        newPhotosPermissions !== 'limited'
      ) {
        alert('Permission to read photos denied');
        return [];
      }
    }
  }

  const { files: result } = await FilePicker.pickVideos({
    limit: 1,
  });

  console.log('pickVideos: result', result);

  const path = result[0].path;

  try {
    const timeStart = new Date().getTime();
    const { compressedUri } = await CapacitorVideoCompress.compressVideo({
      fileUri: path,
    });
    console.log(`compressVideo: compressedUri "${compressedUri}"`);

    await saveVideoToGallery(compressedUri);

    alert(`Compress finished in ${(new Date().getTime() - timeStart) / 1000}s`);
  } catch (e) {
    console.error('An error occurred', e.message);
    alert(`An error occurred: ${e.message}`);
  }
};
