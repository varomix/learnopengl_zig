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
    const vertPath = try join(allocator, &[_][]const u8{ "shaders", "1_3_shaders.vert" });
    const fragPath = try join(allocator, &[_][]const u8{ "shaders", "1_3_shaders.frag" });

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
    var window = c.glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Learning OpenGL - 1-3 Shaders", null, null);
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
        // positions        // colors
         0.5, -0.5, 0.0, 1.0, 0.0, 0.0,     // top right
        -0.5, -0.5, 0.0, 0.0, 1.0, 0.0,     //bottom right
         0.0,  0.5, 0.0, 0.0, 0.0, 1.0,     //bottom left
    };
    // zig fmt: on

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };
    _ = indices;

    var VAO: c_uint = undefined;
    var VBO: c_uint = undefined;
    c.glGenVertexArrays(1, &VAO);
    defer c.glDeleteVertexArrays(1, &VAO);
    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);

    // bind the vertex array object first, then bind and set vertex buffers
    // and then configure the vertex attributes
    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    // position attribute
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    // color attribute
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @intToPtr(*i32, 3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(1);
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
        ourShader.use();
        c.glBindVertexArray(VAO); // seeing as we only have a single VAO there's no need to bind, but we'll do so to keep things a bit more organized
        c.glDrawArrays(c.GL_TRIANGLES, 0, 6);
        // c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
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
