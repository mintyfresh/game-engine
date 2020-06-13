import std.stdio;

import bindbc.glfw;
import bindbc.opengl;
import bindbc.freetype;

immutable string vertexShaderSource = q{
	#version 330 core

	layout (location = 0) in vec3 aPos;

	void main()
	{
		gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
	}
};

immutable string fragmentShaderSource = q{
	#version 330 core

	out vec4 fragColor;

	void main()
	{
		fragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
	}
};

immutable float[] vertices = [
     0.5f,  0.5f, 0.0f,  // top right
     0.5f, -0.5f, 0.0f,  // bottom right
    -0.5f, -0.5f, 0.0f,  // bottom left
    -0.5f,  0.5f, 0.0f   // top left 
];

immutable uint[] indices = [
    0, 1, 3,   // first triangle
    1, 2, 3    // second triangle
];

void main()
{
	prepareGLFW();

	scope (exit)
	{
		glfwTerminate();
	}

	GLFWwindow* window = glfwCreateWindow(800, 600, "Test", null, null);
	assert(window, "Failed to create GLFW Window.");
	glfwMakeContextCurrent(window);
	
	prepareOpenGL();
	glfwSetFramebufferSizeCallback(window, &framebufferSizeCallback);

	uint vertexShader   = compileShader(vertexShaderSource,   GL_VERTEX_SHADER);
	uint fragmentShader = compileShader(fragmentShaderSource, GL_FRAGMENT_SHADER);
	uint shaderProgram  = linkShaders(vertexShader, fragmentShader);

	glDeleteShader(vertexShader);
	glDeleteShader(fragmentShader);

	uint VAO = createVertexArrayObject();
	uint VBO = createVertexBufferObject(vertices);
	uint EBO = createElementBufferObject(indices);

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, null);
	glEnableVertexAttribArray(0);

	while (!glfwWindowShouldClose(window))
	{
		processInput(window);

		glClearColor(0.2, 0.3, 0.3, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);

		glUseProgram(shaderProgram);
		glBindVertexArray(VAO);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
		glBindVertexArray(0);

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	writeln("Done.");
}

private uint createVertexArrayObject()
{
	uint VAO;

	glGenVertexArrays(1, &VAO);
	glBindVertexArray(VAO);

	return VAO;
}

private uint createVertexBufferObject(in float[] vertices)
{
	uint VBO;

	glGenBuffers(1, &VBO);
	glBindBuffer(GL_ARRAY_BUFFER, VBO);
	glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW);

	return VBO;
}

private uint createElementBufferObject(in uint[] indices)
{
	uint EBO;

	glGenBuffers(1, &EBO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * uint.sizeof, indices.ptr, GL_STATIC_DRAW);

	return EBO;
}

private uint linkShaders(uint[] shaders...)
{
	uint program = glCreateProgram();

	foreach (shader; shaders)
	{
		glAttachShader(program, shader);
	}

	glLinkProgram(program);

	int success;
	glGetProgramiv(program, GL_LINK_STATUS, &success);

	if (!success)
	{
		import std.string : fromStringz;

		char[512] infoLog;
		glGetProgramInfoLog(program, 512, null, infoLog.ptr);

		assert(0, infoLog.ptr.fromStringz);
	}

	return program;
}

private uint compileShader(string source, uint type)
{
	uint shader  = glCreateShader(type);
	auto sources = [cast(char*) source.ptr];
	auto lengths = [cast(int) source.length];

	glShaderSource(shader, 1, sources.ptr, lengths.ptr);
	glCompileShader(shader);

	int success;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &success);

	if (!success)
	{
		import std.string : fromStringz;

		char[512] infoLog;
		glGetShaderInfoLog(shader, 512, null, infoLog.ptr);

		assert(0, infoLog.ptr.fromStringz);
	}

	return shader;
}

private extern (C) void framebufferSizeCallback(GLFWwindow* window, int width, int height) nothrow
{
	glViewport(0, 0, width, height);
}

private void processInput(GLFWwindow* window)
{
	if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
	{
		glfwSetWindowShouldClose(window, true);
	}
}

void prepareGLFW()
{
	GLFWSupport result = loadGLFW();

    switch (result)
    {
        case GLFWSupport.badLibrary:
            assert(0, "Bad library");

        case GLFWSupport.noLibrary:
            assert(0, "Missing GLFW.");

        default:
            writefln("Loaded GLFW (%s)", result);
    }

    glfwInit();

    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);

    glfwSetErrorCallback(&appGlobalErrorHandler);
}

private extern (C) void appGlobalErrorHandler(int code, const(char)* message) nothrow
{
    printf("Error(%d, 0x%x): %s\n", code, code, message);
}

void prepareOpenGL()
{
	GLSupport result = loadOpenGL();

    switch (result)
    {
        case GLSupport.badLibrary:
            assert(0, "Bad library");

        case GLSupport.noLibrary:
            assert(0, "Missing OpenGL.");

        default:
            writefln("Loaded OpenGL (%s)", result);
    }
}

void prepareFreeType()
{
	FTSupport result = loadFreeType("freetype.dll");

    switch (result)
    {
        case FTSupport.badLibrary:
            assert(0, "Bad library");

        case FTSupport.noLibrary:
            assert(0, "Missing FreeType.");

        default:
            writefln("Loaded FreeType (%s)", result);
    }
}
