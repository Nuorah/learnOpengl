const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

// Procedure table that will hold OpenGL functions loaded at runtime
var procs: gl.ProcTable = undefined;

const vertices = [9]f32{ -0.5, -0.5, 0, 0.5, -0.5, 0, 0, 0.5, 0 };

const vertexShaderSource = "#version 330 core\nlayout (location = 0) in vec3 aPos;\nvoid main()\n{\n  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n}";
const fragmentShaderSource = "#version 330 core\nout vec4 FragColor;\nvoid main()\n{\n    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n}";

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    const window: glfw.Window = glfw.Window.create(640, 480, "learn opengl", null, null, .{}) orelse {
        std.log.err("failed to create GLFW window:{?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    if (!procs.init(glfw.getProcAddress)) return error.InitFailed;

    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    const vertexShader = gl.CreateShader(gl.VERTEX_SHADER);
    defer gl.DeleteShader(vertexShader);
    gl.ShaderSource(vertexShader, 1, @ptrCast(&vertexShaderSource), null);
    gl.CompileShader(vertexShader);

    var success: c_int = undefined;
    var infoLog: [512]u8 = undefined;
    gl.GetShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.GetShaderInfoLog(vertexShader, 512, null, infoLog[0..512]);
        std.debug.print("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}", .{infoLog});
    }

    const fragmentShader = gl.CreateShader(gl.FRAGMENT_SHADER);
    defer gl.DeleteShader(fragmentShader);
    gl.ShaderSource(fragmentShader, 1, @ptrCast(&fragmentShaderSource), null);
    gl.CompileShader(fragmentShader);

    gl.GetShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.GetShaderInfoLog(fragmentShader, 512, null, infoLog[0..512]);
        std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}", .{infoLog});
    }

    const shaderProgram = gl.CreateProgram();
    defer gl.DeleteProgram(shaderProgram);

    gl.AttachShader(shaderProgram, vertexShader);
    gl.AttachShader(shaderProgram, fragmentShader);
    gl.LinkProgram(shaderProgram);

    gl.GetProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.GetProgramInfoLog(shaderProgram, 512, null, infoLog[0..512]);
        std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}", .{infoLog});
    }

    var VBO: c_uint = undefined;
    gl.GenBuffers(1, @ptrCast(&VBO));
    std.debug.print("VBO::{any}\n", .{VBO});

    var VAO: c_uint = undefined;
    gl.GenVertexArrays(1, @ptrCast(&VAO));
    std.debug.print("VAO::{any}\n", .{VAO});

    gl.BindVertexArray(VAO);
    gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);

    const alpha: gl.float = 1;
    while (!window.shouldClose()) {
        // Input
        processInput(window);
        // Rendering
        gl.ClearColor(0.2, 0.3, 0.3, alpha);
        gl.Clear(gl.COLOR_BUFFER_BIT);
        gl.UseProgram(shaderProgram);
        gl.BindVertexArray(VAO);
        gl.DrawArrays(gl.TRIANGLES, 0, 3);

        // Check and call events and swap the buffers
        glfw.pollEvents();
        window.swapBuffers();
    }
}

pub fn processInput(window: glfw.Window) void {
    if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}
