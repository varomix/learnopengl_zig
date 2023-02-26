const std = @import("std");
const builtin = @import("builtin");
const panic = std.debug.panic;

// const c = @cImport({
// @cInclude("GLFW/glfw3.h");
// });

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
    std.debug.print("Hello OpenGL\n", .{});

    const ok = c.glfwInit();
    if (ok == 0) {
        panic("Failed to initialize GLFW\n", .{});
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);

    // gflw: initialize and configure
    var window = c.glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Learning OpenGL Chapter 1", null, null);
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

    // render loop
    while (c.glfwWindowShouldClose(window) == 0) {
        // input
        processInput(window);

        // render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

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
