import wasm4;
import lines;
import math;
import impl;
import ver;

version(d2d) {}
else:

enum Plane: uint {
    x,
    y,
    z,
}

Quad[] worldData = [
    Quad.face(Color.dark, Plane.x, [10, -1, 0]),
    Quad.face(Color.light, Plane.y, [10, -1, 0]),
    Quad.face(Color.black, Plane.z, [10, -1, 0]),
    // Quad.face(Color.dark, Plane.z, [-5, 0, -1]),
    // Quad.face(Color.dark, Plane.z, [-1, 0, -1]),
];

enum Color : ushort {
    white = 0x41,
    light = 0x42,
    dark = 0x43,
    black = 0x44,
}

struct Data {
    Camera camera;
    int time;
    bool button1;
    bool button2;
}

struct Camera  {
    float rot;
    float[3] pos;
}

struct Pixel {
    short[2] xy;
    bool has;

    static Pixel none(float x=0, float y=0) {
        return Pixel([cast(float) 0, cast(float) 0], false);
    }

    static Pixel from(float x, float y) {
        return Pixel([cast(short) x, cast(short) y], true);
    }

    float opIndex(ubyte i) {
        return cast(float) xy[i];
    }

    float[2] vec() {
        return [cast(float) xy[0], cast(float) xy[1]];
    }
}

struct Triangle {
    Color color = Color.black;
    float[3] p1;
    float[3] p2;
    float[3] p3;

    void draw(Camera camera) {
        Pixel start = toPixelCamera(this.p2, camera);
        Pixel end = toPixelCamera(this.p3, camera);
        Pixel from = toPixelCamera(this.p1, camera);
        if (!start.has && !end.has && !from.has) {
            return; 
        }
        float iters = distance(start.vec, end.vec) * 1;
        foreach (i; 0..iters) {
            float n = i / iters;
            *drawColors = this.color;
            line(cast(int) from[0], cast(int) from[1], cast(int) lerp(end[0], start[0], n), cast(int) lerp(end[1], start[1], n));
        }
    }
}

struct Quad {
    Triangle t1;
    Triangle t2;

    this(Color c, float[3] p1, float[3] p2, float[3] p3, float[3] p4) {
        t1 = Triangle(c, p1, p2, p3);
        t2 = Triangle(c, p1, p3, p4);
    }

    static Quad face(Color color, Plane plane, float[3] pos) {
        final switch (plane) {
        case Plane.x:
            return Quad(
                color,
                [pos[0], pos[1], pos[2]],
                [pos[0], pos[1], pos[2] + 1],
                [pos[0], pos[1] + 1, pos[2] + 1],
                [pos[0], pos[1] + 1, pos[2]],
            );
        case Plane.y:
            return Quad(
                color,
                [pos[0], pos[1], pos[2]],
                [pos[0], pos[1], pos[2] + 1],
                [pos[0] + 1, pos[1], pos[2] + 1],
                [pos[0] + 1, pos[1], pos[2]],
            );
        case Plane.z:
            return Quad(
                color,
                [pos[0], pos[1], pos[2]],
                [pos[0], pos[1] + 1, pos[2]],
                [pos[0] + 1, pos[1] + 1, pos[2]],
                [pos[0] + 1, pos[1], pos[2]],
            );
        }
    }

    void draw(Camera camera) {
        t1.draw(camera);
        t2.draw(camera);
    }
}

struct Voxel {

}

Data getData() {
    Data ret;
    diskr(&ret, Data.sizeof);
    return ret;
}

void setData(Data val) {
    diskw(&val, Data.sizeof);
}

enum Type : ubyte {
    none,
    light,
    medium,
    dark,
    lightStripes,
    darkStripes,
}

enum zoom = 10;
enum fov = 90;
enum viewDist = 12;
enum accuracy = 8;
enum speed = 0.05;
enum extraRenders = 40;

extern(C) void start() {
    Data data;
    data.time = 0;
    data.camera = Camera(0, [0, 0, 0]);
    setData(data);
}

Data gameTick() {
    Data oldData = getData;
    Data newData = oldData;
    
    ubyte gamepad = *gamepad1;
    if (gamepad & buttonRight) {
        newData.camera.rot -= 0.02;
    }
    if (gamepad & buttonLeft) {
        newData.camera.rot += 0.02;
    }
    if (gamepad & buttonUp) {
        newData.camera.pos[0] += sin(-newData.camera.rot) * speed;
        newData.camera.pos[2] += cos(-newData.camera.rot) * speed;
    }
    if (gamepad & buttonDown) {
        newData.camera.pos[0] -= sin(-newData.camera.rot) * speed;
        newData.camera.pos[2] -= cos(-newData.camera.rot) * speed;
    }
    newData.button1 = (gamepad & button1) != 0;
    newData.button2 = (gamepad & button2) != 0;

    tracef("%f %f", newData.camera.pos[0], newData.camera.pos[1]);

    newData.time += 1;

    if (newData.camera.rot < -PI * 2) {
        newData.camera.rot += PI * 2;
    }
    if (newData.camera.rot > PI * 2) {
        newData.camera.rot -= PI * 2;
    }

    setData(newData);
    return newData;
}

float[2] rotate(float[2] n, float rot) {
    float len = distance(n, cast(float[2]) [0, 0]);
    float at2 = atan2(n[0], n[1]) + rot;
    return [cos(at2) * len, sin(at2) * len];
}

Pixel toPixel(float[3] offset) {
    if (abs(offset[2]) < 0.01) {
        if (offset[2] < 0) {
            offset[2] = -0.01;
        } else {
            offset[2] = 0.01;
        }
    }
    float rotx = atan2(offset[2], offset[0]) / PI * 2;
    float roty = atan2(offset[1], offset[0]) / PI * 2;
    return Pixel.from(rotx * 160 + 80, roty * 160 + 80);
}

Pixel toPixel(float[3] offset, float rot) {
    float[2] point = rotate([offset[0], offset[2]], rot);
    offset[0] = point[0];
    offset[2] = point[1];
    return toPixel(offset);
}

Pixel toPixelCamera(float[3] point, Camera camera) {
    float[3] diff = [point[0] - camera.pos[0], point[1] - camera.pos[1], point[2] - camera.pos[2]];
    // float[3] diff = [camera.pos[0] - point[0], camera.pos[1] - point[1], camera.pos[2] - point[2]];
    return toPixel(diff, cast(float) camera.rot);
}

extern(C) void update() {
    Data data = gameTick();

    int n = (data.time % 360 + 360) % 360;
    foreach (tri; worldData) {
        tri.draw(data.camera);
    }
}
