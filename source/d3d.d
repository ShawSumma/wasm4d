import wasm4;
import lines;
import math;
import ver;

version(d2d) {}
else:

enum Plane: uint {
    x,
    y,
    z,
}

Quad[] worldData = [
    Quad.face(Color.black, Plane.z, [0, 0, 3]),
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
    int rot;
    float[3] pos;
}

struct Triangle {
    Color color = Color.black;
    float[3] p1;
    float[3] p2;
    float[3] p3;

    void draw(Camera camera) {
        float[2] start = toPixelCamera(this.p2, camera);
        float[2] end = toPixelCamera(this.p3, camera);
        float[2] from = toPixelCamera(this.p1, camera);
        float iters = distance(start, end) * 1;
        foreach (i; 0..iters) {
            float n = i / iters;
            *drawColors = this.color;
            line(cast(int) from[0], cast(int) from[1], cast(int) lerp(end[0], start[0], n), cast(int) lerp(end[1], start[1], n));
        }
    }
}

struct Quad {
    Color color = Color.black;
    float[3] p1;
    float[3] p2;
    float[3] p3;
    float[3] p4;

    static Quad face(Color color, Plane plane, float[3] pos) {
        final switch (plane) {
        case Plane.x:
        case Plane.y:
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
        float[2] pix1 = toPixelCamera(this.p1, camera);
        float[2] pix2 = toPixelCamera(this.p2, camera);
        float[2] pix3 = toPixelCamera(this.p3, camera);
        float[2] pix4 = toPixelCamera(this.p4, camera);
        float itersEnd = distance(pix1, pix2);
        float itersBegin = distance(pix4, pix3);
        float iters = max(itersBegin, itersEnd);
        foreach (i; 0..iters) {
            float alongBegin = i / iters * itersBegin;
            float alongEnd = i / iters * itersEnd;
            line(
                cast(int) lerp(pix1[0], pix2[0], alongBegin),
                cast(int) lerp(pix1[1], pix2[1], alongBegin),
                cast(int) lerp(pix4[0], pix3[0], alongEnd),
                cast(int) lerp(pix4[1], pix3[1], alongEnd),
            );
        }
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
        newData.camera.rot -= 2;
    }
    if (gamepad & buttonLeft) {
        newData.camera.rot += 2;
    }
    if (gamepad & buttonUp) {
        newData.camera.pos[0] += sine(newData.camera.rot) * speed;
        newData.camera.pos[2] += cosine(newData.camera.rot) * speed;
    }
    if (gamepad & buttonDown) {
        newData.camera.pos[0] -= sine(newData.camera.rot) * speed;
        newData.camera.pos[2] -= cosine(newData.camera.rot) * speed;
    }
    newData.button1 = (gamepad & button1) != 0;
    newData.button2 = (gamepad & button2) != 0;

    newData.time += 1;

    if (newData.camera.rot < 0) {
        newData.camera.rot += 360;
    }
    if (newData.camera.rot > 360) {
        newData.camera.rot -= 360;
    }
 
    setData(newData);
    return newData;
}

float[2] rotate(float[2] n, float rot) {
    float cos = cosine(rot);
    float sin = sine(rot);
    return [n[0] * cos + n[1] * sin, n[0] * sin + n[1] * cos];
}

float[2] toPixel(float[3] offset) {
    if (offset[2] < 0) {
        offset[2] = 0;
    }
    float dist = distance(offset, cast(float[3])[0, 0, 0]);
    if (dist < 0.01) {
        dist = 0.01;
    }
    // float px = offset[0] / offset[2];
    float rotx = offset[0] / dist;
    float roty = offset[1] / dist;
    return [80 + rotx * 180 / PI * 4, 80 - roty * 180 / PI * 4];
}

float[2] toPixel(float[3] offset, float rot) {
    float[2] point = rotate([offset[0], offset[2]], cast(float)(cast(int) rot));
    offset[0] = point[0];
    offset[2] = point[1];
    return toPixel(offset);
}

float[2] toPixelCamera(float[3] point, Camera camera) {
    float[3] diff = [point[0] - camera.pos[0], point[1] - camera.pos[1], point[2] - camera.pos[2]];
    return toPixel(diff, camera.rot);
}

extern(C) void update() {
    Data data = gameTick();

    int n = (data.time % 360 + 360) % 360;
    foreach (tri; worldData) {
        tri.draw(data.camera);
    }
}
