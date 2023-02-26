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

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    const vertPath = try join(allocator, &[_][]const u8{ "shaders", "1_4_textures.vert" });
    const fragPath = try join(allocator, &[_][]const u8{ "shaders", "1_4_textures.frag" });

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
    var window = c.glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Learning OpenGL - 1-4 Textures", null, null);
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
    const ourShader = try Shader.init(&allocator, vertPath, fragPath);

    // setup vertex data and buffers
    // zig fmt: off
    const vertices = [_]f32{
        // positions     // colors   // texture coords
         0.5,  0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,     // top right
         0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0,     // bottom right
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,     // bottom left
        -0.5,  0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,     // top left
    };
    // zig fmt: on

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

    // bind the vertex array object first, then bind and set vertex buffers
    // and then configure the vertex attributes
    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices, c.GL_STATIC_DRAW);

    // position attribute
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    // color attribute
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @intToPtr(*i32, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);

    // texture coord attribute
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @intToPtr(*i32, 6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(2);

    // load and create a texture
    var texture1: c_uint = undefined;
    var texture2: c_uint = undefined;

    // texture 1
    c.glGenTextures(1, &texture1);
    c.glBindTexture(c.GL_TEXTURE_2D, texture1);
    // set the texture wrapping parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    // set texture filtering parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    // load image, create texture and generate mipmaps
    var width: c_int = undefined;
    var height: c_int = undefined;
    var nrChannels: c_int = undefined;
    c.stbi_set_flip_vertically_on_load(1);
    var data = c.stbi_load("textures/container.jpg", &width, &height, &nrChannels, 0);
    if (data != null) {
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width, height, 0, c.GL_RGB, c.GL_UNSIGNED_BYTE, data);
        c.glGenerateMipmap(c.GL_TEXTURE_2D);
    } else {
        std.debug.print("Failed to load texture\n", .{});
    }
    c.stbi_image_free(data);

    // texture 2
    c.glGenTextures(1, &texture2);
    c.glBindTexture(c.GL_TEXTURE_2D, texture2);
    // set the texture wrapping parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    // set texture filtering parameters
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
    // load image, create texture and generate mipmaps
    c.stbi_set_flip_vertically_on_load(1);
    data = c.stbi_load("textures/awesomeface.png", &width, &height, &nrChannels, 0);
    if (data != null) {
        c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, width, height, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, data);
        c.glGenerateMipmap(c.GL_TEXTURE_2D);
    } else {
        std.debug.print("Failed to load texture\n", .{});
    }
    c.stbi_image_free(data);

    // tell opengl for each sampler to which texture unit it belogs to
    // only has to be done once
    // don't forget to activate/use the shader before setting uniforms!
    ourShader.use();
    // either set it manually like so:
    c.glUniform1i(c.glGetUniformLocation(ourShader.id, "texture1"), 0);
    // or set it via the texture class
    ourShader.setInt("texture2", 1);

    // uncomment this call to draw in wireframe polygons
    // c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    // render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        // input
        processInput(window);

        // render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // bind textures on corresponding texture units
        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        // render container
        ourShader.use();
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
