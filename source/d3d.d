import wasm4;
import lines;
import math;
import algo;
import ver;

version(d2d) {}
else:

Cube[] worldData = [
    Cube(Color.dark, [0, 0, 0]),
    Cube(Color.light, [0, 1, 0]),
    Cube(Color.dark, [0, 2, 0]),
    Cube(Color.light, [-1, 2, 0]),
    Cube(Color.dark, [-2, 2, 0]),
    Cube(Color.light, [0, 3, 0]),
    Cube(Color.light, [-2, 3, 0]),
    Cube(Color.dark, [0, 4, 0]),
    Cube(Color.dark, [-2, 4, 0]),
];

enum Plane: uint {
    x,
    y,
    z,
}

enum Color : ubyte {
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
    Color color;
    float[3] p1;
    float[3] p2;
    float[3] p3;
    float[3] p4;

    this(Color c, float[3] a1, float[3] a2, float[3] a3, float[3] a4) {
        color = c;
        p1 = a1;
        p2 = a2;
        p3 = a3;
        p4 = a4;
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

    float[3] center() {
        float[3] all = [0, 0, 0];
        foreach (sub; [p1, p2, p3, p4]) {
            all[0] += sub[0];
            all[1] += sub[1];
            all[2] += sub[2];
        }
        all[0] /= 4;
        all[1] /= 4;
        all[2] /= 4;
        return all;
    }

    void draw(Camera camera) {
        Triangle t1 = Triangle(color, p1, p2, p3);
        Triangle t2 = Triangle(color, p1, p3, p4);
        t1.draw(camera);
        t2.draw(camera);
    }
}

struct Cube {
    Color color;
    byte[3] pos;

    void draw(Camera camera) {
        float[3] fpos = [cast(float) pos[0], cast(float) pos[1], cast(float) pos[2]];
        Quad ax = Quad.face(color, Plane.x, fpos);
        Quad ay = Quad.face(color, Plane.y, fpos);
        Quad az = Quad.face(color, Plane.z, fpos);
        Quad bx = Quad.face(color, Plane.x, [fpos[0] + 1, fpos[1], fpos[2]]);
        Quad by = Quad.face(color, Plane.y, [fpos[0], fpos[1] + 1, fpos[2]]);
        Quad bz = Quad.face(color, Plane.z, [fpos[0], fpos[1], fpos[2] + 1]);
        ax.draw(camera);
        ay.draw(camera);
        az.draw(camera);
        bx.draw(camera);
        by.draw(camera);
        bz.draw(camera);
    }

    float dist(float[3] val) {
        float[3] fpos = [0.5 + cast(float) pos[0], 0.5 + cast(float) pos[1], 0.5 + cast(float) pos[2]];
        return distance(fpos, val);
    }
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


Data gameTick() {
    Data oldData = getData;
    Data newData = oldData;
    
    ubyte gamepad = *gamepad1;
    if (gamepad & buttonRight) {
        newData.camera.rot -= 0.03;
    }
    if (gamepad & buttonLeft) {
        newData.camera.rot += 0.03;
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
    float roty = -atan2(offset[1], offset[0]) / PI * 2;
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
    return toPixel(diff, cast(float) camera.rot);
}

void fixWorldLocsCamera(Camera camera) {
    foreach (i; 0..worldData.length) {
        float best = worldData[i].dist(camera.pos);
        foreach (j; i..worldData.length) {
            float cur = worldData[j].dist(camera.pos);
            if (cur > best) {
                best = cur;
                swap(worldData[i], worldData[j]);
            }
        }
    }
}

extern(C) void start() {
    Data data;
    data.time = 0;
    data.camera = Camera(0, [0.1, 0.5, -20]);
    setData(data);
}

extern(C) void update() {
    Data data = gameTick();

    if (data.time % 10 == 0) {
        fixWorldLocsCamera(data.camera);
    }

    int n = (data.time % 360 + 360) % 360;
    foreach (thing; worldData) {
        thing.draw(data.camera);
    }
}
