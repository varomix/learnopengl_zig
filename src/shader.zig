const std = @import("std");
const builtin = @import("builtin");
const panic = std.debug.panic;
const Allocator = std.mem.Allocator;
const cwd = std.fs.cwd;
const OpenFlags = std.fs.File.OpenFlags;

const glm = @import("glm.zig");
const Mat4 = glm.Mat4;
const Vec3 = glm.Vec3;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("stb_image.h");
});
// usingnamespace @import("c.zig");

pub const Shader = struct {
    id: c_uint,

    pub fn init(allocator: *Allocator, vertexPath: []const u8, fragmentPath: []const u8) !Shader {
        // 1. retrieve the vertex/fragment source code from filePath
        const vShaderFile = try cwd().openFile(vertexPath, .{});
        defer vShaderFile.close();

        const fShaderFile = try cwd().openFile(fragmentPath, .{});
        defer fShaderFile.close();

        var vertexCode = try allocator.alloc(u8, try vShaderFile.getEndPos());
        defer allocator.free(vertexCode);

        var fragmentCode = try allocator.alloc(u8, try fShaderFile.getEndPos());
        defer allocator.free(fragmentCode);

        const vLen = try vShaderFile.read(vertexCode);
        _ = vLen;
        const fLen = try fShaderFile.read(fragmentCode);
        _ = fLen;

        // 2. compile shaders
        // vertex shader
        const vertex = c.glCreateShader(c.GL_VERTEX_SHADER);
        const vertexSrcPtr: ?[*]const u8 = vertexCode.ptr;
        c.glShaderSource(vertex, 1, &vertexSrcPtr, null);
        c.glCompileShader(vertex);
        checkCompileErrors(vertex, "VERTEX");
        // fragment Shader
        const fragment = c.glCreateShader(c.GL_FRAGMENT_SHADER);
        const fragmentSrcPtr: ?[*]const u8 = fragmentCode.ptr;
        c.glShaderSource(fragment, 1, &fragmentSrcPtr, null);
        c.glCompileShader(fragment);
        checkCompileErrors(fragment, "FRAGMENT");
        // shader Program
        const id = c.glCreateProgram();
        c.glAttachShader(id, vertex);
        c.glAttachShader(id, fragment);
        c.glLinkProgram(id);
        checkCompileErrors(id, "PROGRAM");
        // delete the shaders as they're linked into our program now and no longer necessary
        c.glDeleteShader(vertex);
        c.glDeleteShader(fragment);

        return Shader{ .id = id };
    }

    pub fn use(self: Shader) void {
        c.glUseProgram(self.id);
    }

    pub fn setBool(self: Shader, name: [:0]const u8, val: bool) void {
        _ = val;
        _ = name;
        _ = self;
        // glUniform1i(glGetUniformLocation(ID, name.c_str()), (int)value);
    }

    pub fn setInt(self: Shader, name: [:0]const u8, val: c_int) void {
        c.glUniform1i(c.glGetUniformLocation(self.id, name), val);
    }

    pub fn setFloat(self: Shader, name: [:0]const u8, val: f32) void {
        c.glUniform1f(c.glGetUniformLocation(self.id, name), val);
    }

    pub fn setMat4(self: Shader, name: [:0]const u8, val: Mat4) void {
        c.glUniformMatrix4fv(c.glGetUniformLocation(self.id, name), 1, c.GL_FALSE, &val.vals[0][0]);
    }

    pub fn setVec3(self: Shader, name: [:0]const u8, val: Vec3) void {
        c.glUniform3f(c.glGetUniformLocation(self.id, name), val.vals[0], val.vals[1], val.vals[2]);
    }

    fn checkCompileErrors(shader: c_uint, errType: []const u8) void {
        var success: c_int = undefined;
        var infoLog: [1024]u8 = undefined;
        if (!std.mem.eql(u8, errType, "PROGRAM")) {
            c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &success);
            if (success == 0) {
                c.glGetShaderInfoLog(shader, 1024, null, &infoLog);
                panic("ERROR::SHADER::{s}::COMPILATION_FAILED\n{s}\n", .{ errType, infoLog });
            }
        } else {
            c.glGetShaderiv(shader, c.GL_LINK_STATUS, &success);
            if (success == 0) {
                c.glGetShaderInfoLog(shader, 1024, null, &infoLog);
                panic("ERROR::SHADER::LINKING_FAILED\n{s}\n", .{infoLog});
            }
        }
    }
};
