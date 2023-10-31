import { createTransform } from "redux-persist";
import { compressToUTF16, decompressFromUTF16 } from "lz-string";
import stringify from "json-stringify-safe";

const NODE_ENV = typeof process !== "undefined" ? process.env.NODE_ENV : "production";

interface TransformConfig {
    whitelist?: Array<string>;
    blacklist?: Array<string>;
  }

const createTransformCompress = (config?: TransformConfig) => {
    return createTransform(
        (state) => compressToUTF16(stringify(state)),
        (state) => {
            if (typeof state !== "string") {
                if (NODE_ENV !== "production") {
                    console.error("redux-persist-transform-compress: expected outbound state to be a string")
                }
                return state
            }

            try {
                return JSON.parse(decompressFromUTF16(state))
            } catch (err) {
                if (NODE_ENV !== "production") {
                    console.error("redux-persist-transform-compress: error while decompressing state", err)
                }
                return null
            }
        },
        config
    )
}

export default createTransformCompress;