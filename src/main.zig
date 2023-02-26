const std = @import("std");
const builtin = @import("builtin");
const panic = std.debug.panic;
const join = std.fs.path.join;

// const c = @cImport({
// @cInclude("GLFW/glfw3.h");
// });

const Shader = @import("shader.zig").Shader;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
    @cInclude("stb_image.h");
});

// usingnamespace @import("c.zig");

// settings
const SCR_WIDTH: u32 = 1920;
const SCR_HEIGHT: u32 = 1080;

const vertexShaderSource: [:0]const u8 =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main()
    \\{
    \\   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;
const fragmentShaderSource: [:0]const u8 =
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const vertPath = try join(allocator, &[_][]const u8{ "shaders", "1_3_shaders.vert" });
    _ = vertPath;
    const fragPath = try join(allocator, &[_][]const u8{ "shaders", "1_3_shaders.frag" });
    _ = fragPath;

    const ok = c.glfwInit();
    if (ok == 0) {
        panic("Failed to initialize GLFW\n", .{});
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    // gflw: initialize and configure
    var window = c.glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Learning OpenGL Chapter 3", null, null);
    if (window == null) {
        panic("Failed to create GLFW window\n", .{});
    }

    c.glfwMakeContextCurrent(window);
    const resizeCallback = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    _ = resizeCallback;

    // glad: load all OpenGL function pointers
    if (c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress)) == 0) {
        panic("Failed to initialize GLAD\n", .{});
    }

    // build and compile our shader program

    // vertex shader
    const vertexShader = c.glCreateShader(c.GL_VERTEX_SHADER);
    const vertexSrcPtr: ?[*]const u8 = vertexShaderSource.ptr;
    // std.debug.print("vertexShader {any}\n", .{vertexSrcPtr});
    c.glShaderSource(vertexShader, 1, &vertexSrcPtr, null);
    c.glCompileShader(vertexShader);

    // check for shader compile errors
    var success: c_int = undefined;
    var infoLog: [512]u8 = undefined;
    c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(vertexShader, 512, null, &infoLog);
        panic("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{infoLog});
    }

    // fragment shader
    const fragmentShader = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    const fragmentSrcPtr: ?[*]const u8 = fragmentShaderSource.ptr;
    c.glShaderSource(fragmentShader, 1, &fragmentSrcPtr, null);
    c.glCompileShader(fragmentShader);
    // check for shader compile errors
    c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(fragmentShader, 512, null, &infoLog);
        panic("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{any}\n", .{infoLog});
    }

    // link shaders
    const shaderProgram = c.glCreateProgram();
    c.glAttachShader(shaderProgram, vertexShader);
    c.glAttachShader(shaderProgram, fragmentShader);
    c.glLinkProgram(shaderProgram);
    // check for link errors
    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, &success);
    if (success == 0) {
        c.glGetShaderInfoLog(shaderProgram, 512, null, &infoLog);
        panic("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{any}\n", .{infoLog});
    }
    c.glDeleteShader(vertexShader);
    c.glDeleteShader(fragmentShader);

    // setup vertex data and buffers
    const vertices = [_]f32{
        0.5, 0.5, 0.0, // top right
        0.5, -0.5, 0.0, //bottom right
        -0.5, -0.5, 0.0, //bottom left
        -0.5, 0.5, 0.0, // top left
    };

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };

    var VAO: c_uint = undefined;
    var VBO: c_uint = undefined;
    var EBO: c_uint = undefined;
    c.glGenVertexArrays(1, &VAO);
    defer c.glDeleteVertexArrays(1, &VAO);
    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);
    c.glGenBuffers(1, &EBO);
    defer c.glDeleteBuffers(1, &EBO);

    // bind the vertex arrat object first, then bind and set vertex buffers
    // and then configure the vertex attributes
    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    // remember: do NOT unbind the EBO while a VAO is active as the bound
    // element object IS stored in

    // You can unbind the VAO afterwards so other VAO calls won't
    // accidentally modify this VAO, but this rarely happens.
    // Modifying other VAOs requires a call to glBindVertexArray anyways so we
    // generally don't unbind VAOs (nor VBOs) when it's not directly necessary.
    c.glBindVertexArray(0);

    // uncomment this call to draw in wireframe polygons
    // c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    // render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        // input
        processInput(window);

        // render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // draw our first triangle
        c.glUseProgram(shaderProgram);
        c.glBindVertexArray(VAO); // seeing as we only have a single VAO there's no need to bind, but we'll do so to keep things a bit more organized

        // c.glDrawArrays(c.GL_TRIANGLES, 0, 6);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
        // c.glBindVertexArray(0);

        // glfw: swap buffers
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}

// process all input: query GLFW whether relevant keys are pressed/released
pub fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(window, 1);
}

// glfw : whenever the window size changes
pub fn framebuffer_size_callback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    c.glViewport(0, 0, width, height);
}
