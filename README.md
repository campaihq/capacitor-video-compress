# capacitor-video-compress

compress videos.

## Install

```bash
npm install capacitor-video-compress
npx cap sync
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`compressVideo(...)`](#compressvideo)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### echo(...)

```typescript
echo(options: { value: string; }) => Promise<{ value: string; }>
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ value: string; }</code> |

**Returns:** <code>Promise&lt;{ value: string; }&gt;</code>

--------------------


### compressVideo(...)

```typescript
compressVideo(options: { fileUri: string; }) => Promise<{ compressedUri: string; }>
```

| Param         | Type                              |
| ------------- | --------------------------------- |
| **`options`** | <code>{ fileUri: string; }</code> |

**Returns:** <code>Promise&lt;{ compressedUri: string; }&gt;</code>

--------------------

</docgen-api>
