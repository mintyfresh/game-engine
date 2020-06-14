module engine.window;

import bindbc.glfw;

import std.string;

import utils.matrix;

struct WindowConfig
{
    string title;
    int    width;
    int    height;
}

struct WindowDimension
{
    int width;
    int height;
}

struct Window
{
private:
    GLFWwindow* _window;

public:
    this(WindowConfig config)
    {
        _window = glfwCreateWindow(config.width, config.height, config.title.toStringz, null, null);
        assert(_window, "Failed to Create GLFW Window.");
    }

    this(GLFWwindow* window) nothrow
    {
        _window = window;
    }

    @property
    WindowDimension dimensions()
    {
        int width, height;

        glfwGetFramebufferSize(_window, &width, &height);

        return WindowDimension(width, height);
    }

    @property
    Mat4 projection()
    {
        auto dimensions = this.dimensions;

        return Mat4.orthographic(0, dimensions.width, 0, dimensions.height, -1, 1);
    }

    void makeContextCurrent()
    {
        glfwMakeContextCurrent(_window);
    }

    void setKeyCallback(alias callback)()
    {
        extern (C) void _internalCallback(GLFWwindow* window, int key, int scancode, int action, int mode) nothrow
        {
            callback(Window(window), key, scancode, action, mode);
        }

        glfwSetKeyCallback(_window, &_internalCallback);
    }

    void setFramebufferSizeCallback(alias callback)()
    {
        extern (C) void _internalCallback(GLFWwindow* window, int width, int height) nothrow
        {
            callback(Window(window), width, height);
        }

        glfwSetFramebufferSizeCallback(_window, &_internalCallback);
    }

    void swapBuffers()
    {
        glfwSwapBuffers(_window);
    }

    int getKey(int key)
    {
        return glfwGetKey(_window, key);
    }

    @property
    bool shouldClose() nothrow
    {
        return cast(bool) glfwWindowShouldClose(_window);
    }

    @property
    void shouldClose(bool value) nothrow
    {
        glfwSetWindowShouldClose(_window, value);
    }
}
