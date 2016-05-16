
#if os(Linux)
#if GLES
    import COpenGLES.gles2
    #else
    import COpenGL
#endif
#else
#if GLES
    import OpenGLES
    #else
    import OpenGL.GL3
#endif
#endif

import Foundation

public let sharedImageProcessingContext = OpenGLContext()

extension OpenGLContext {
    public func programForVertexShader(vertexShader:String, fragmentShader:String) throws -> ShaderProgram {
        let lookupKeyForShaderProgram = "V: \(vertexShader) - F: \(fragmentShader)"
        if let shaderFromCache = shaderCache[lookupKeyForShaderProgram] {
            return shaderFromCache
        } else {
            return try sharedImageProcessingContext.runOperationSynchronously{
                let program = try ShaderProgram(vertexShader:vertexShader, fragmentShader:fragmentShader)
                self.shaderCache[lookupKeyForShaderProgram] = program
                return program
            }
        }
    }

    public func programForVertexShader(vertexShader:String, fragmentShader:NSURL) throws -> ShaderProgram {
        return try programForVertexShader(vertexShader, fragmentShader:try shaderFromFile(fragmentShader))
    }
    
    public func programForVertexShader(vertexShader:NSURL, fragmentShader:NSURL) throws -> ShaderProgram {
        return try programForVertexShader(try shaderFromFile(vertexShader), fragmentShader:try shaderFromFile(fragmentShader))
    }
    
    public func openGLDeviceSettingForOption(option:Int32) -> GLint {
        return self.runOperationSynchronously{() -> GLint in
            self.makeCurrentContext()
            var openGLValue:GLint = 0
            glGetIntegerv(GLenum(option), &openGLValue)
            return openGLValue
        }
    }
 
    public func deviceSupportsExtension(openGLExtension:String) -> Bool {
#if os(Linux)
        return false
#else
        return self.extensionString.containsString(openGLExtension)
#endif
    }
    
    // http://www.khronos.org/registry/gles/extensions/EXT/EXT_texture_rg.txt
    
    public func deviceSupportsRedTextures() -> Bool {
        return deviceSupportsExtension("GL_EXT_texture_rg")
    }

    public func deviceSupportsFramebufferReads() -> Bool {
        return deviceSupportsExtension("GL_EXT_shader_framebuffer_fetch")
    }
    
    public func sizeThatFitsWithinATextureForSize(size:Size) -> Size {
        let maxTextureSize = Float(self.maximumTextureSizeForThisDevice)
        if ( (size.width < maxTextureSize) && (size.height < maxTextureSize) ) {
            return size
        }
        
        let adjustedSize:Size
        if (size.width > size.height) {
            adjustedSize = Size(width:maxTextureSize, height:(maxTextureSize / size.width) * size.height)
        } else {
            adjustedSize = Size(width:(maxTextureSize / size.height) * size.width, height:maxTextureSize)
        }
        
        return adjustedSize
    }
}