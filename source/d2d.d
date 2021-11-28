import wasm4;
import lines;
import math;
import ver;

version(d2d):

Wall[] worldData = [
    Wall(Type.lightStripes, [-4, -4], [-4, 4]),
    Wall(Type.darkStripes, [-4, 4], [4, 4]),
    Wall(Type.lightStripes, [4, 4], [4, -4]),
    Wall(Type.darkStripes, [4, -4], [-4, -4]),
];

enum Mode {
    steel,
    fruit,
    rgb,
    stop,
    start = steel,
}

struct Data {
    float x;
    float y;
    int time;
    int rot;
    Mode mode;
    bool button1;
    bool button2;

    float[2] pos() {
        return [x, y];
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

struct Wall {
    Type type;
    byte[2] start;
    byte[2] end;
}

struct Collision {
    enum Collision none = Collision();

    Wall block = Wall(Type.none);
    float[2] pos = void;

    bool isHit() {
        return block.type != Type.none;
    }
}

Collision collides(float[2] rayStart, float[2] rayEnd) {
    foreach(x, wall; worldData) {
        if (intersects(rayStart, rayEnd, [wall.start[0], wall.start[1]], [wall.start[0], wall.end[1]])) {
            return Collision(wall, intersectsWhere(rayStart, rayEnd, [wall.start[0], wall.start[1]], [wall.start[0], wall.end[1]]));
        }
        if (intersects(rayStart, rayEnd, [wall.start[0], wall.start[1]], [wall.end[0], wall.end[1]])) {
            return Collision(wall, intersectsWhere(rayStart, rayEnd, [wall.start[0], wall.start[1]], [wall.end[0], wall.end[1]]));
        }
        if (intersects(rayStart, rayEnd, [wall.end[0], wall.end[1]], [wall.start[0], wall.end[1]])) {
            return Collision(wall, intersectsWhere(rayStart, rayEnd, [wall.end[0], wall.end[1]], [wall.start[0], wall.end[1]]));
        }
        if (intersects(rayStart, rayEnd, [wall.end[0], wall.end[1]], [wall.end[0], wall.end[1]])) {
            return Collision(wall, intersectsWhere(rayStart, rayEnd, [wall.end[0], wall.end[1]], [wall.end[0], wall.end[1]]));
        }
    }
    return Collision.none;
}

int[2] val(int n, int rot, float[2] pos) {
    int angle = cast(int) ((80 - n) * 180 / 80 * fov / 360 + rot);
    float[2] where = [pos[0], pos[1]];
    float[2] speed = [sine(angle) / accuracy, cosine(angle) / accuracy];
    int max = viewDist * accuracy;
    foreach (i; 0..max) {
        float[2] rayStart = [where[0], where[1]];
        where[0] += speed[0];
        where[1] += speed[1];
        float[2] rayEnd = [where[0], where[1]];
        Collision hit = collides(rayStart, rayEnd);
        if (hit.isHit != 0) {
            int ret2 = cast(int) (60 * 90 / fov * invDistance(hit.pos, pos));
            final switch (hit.block.type) {
            case Type.none:
                assert(false);
            case Type.dark:
                return [3, ret2];
            case Type.medium:
                return [2, ret2];
            case Type.light:
                return [1, ret2];
            case Type.lightStripes:
                int fromStart = cast(int) distance([cast(float) hit.block.start[0], cast(float) hit.block.start[1]], hit.pos);
                if (fromStart % 2 == 0) {
                    return [2, ret2];
                } else {
                    return [1, ret2];
                }
            case Type.darkStripes:
                int fromStart = cast(int) distance([cast(float) hit.block.start[0], cast(float) hit.block.start[1]], hit.pos);
                if (fromStart % 2 == 0) {
                    return [3, ret2];
                } else {
                    return [2, ret2];
                }
            }
        }
    }
    return [0, 0];
}

enum fov = 90;
enum viewDist = 12;
enum accuracy = 8;
enum speed = 0.05;

Data gameTick() {
    Data oldData = getData;
    Data newData = oldData;
    
    ubyte gamepad = *gamepad1;
    if (gamepad & buttonRight) {
        newData.rot -= 2;
    }
    if (gamepad & buttonLeft) {
        newData.rot += 2;
    }
    if (gamepad & buttonUp) {
        newData.x += sine(newData.rot) * speed;
        newData.y += cosine(newData.rot) * speed;
    }
    if (gamepad & buttonDown) {
        newData.x -= sine(newData.rot) * speed;
        newData.y -= cosine(newData.rot) * speed;
    }
    newData.button1 = (gamepad & button1) != 0;
    newData.button2 = (gamepad & button2) != 0;

    if (newData.button1 && !oldData.button1) {
        newData.mode += 1;
        if (newData.mode == Mode.stop) {
            newData.mode = Mode.start;
        }
    }

    if (collides(oldData.pos, newData.pos).isHit) {
        newData.x = oldData.x;
        newData.y = oldData.y;
    }

    newData.time += 1;

    if (newData.rot < 0) {
        newData.rot += 360;
    }
    if (newData.rot > 360) {
        newData.rot -= 360;
    }
 
    setData(newData);
    return newData;
}

uint sineMod(int angle, uint max) {
    return (cast(uint)((sine(angle) + 1) * max / 2) % max);
}

uint angleRgb(int angle) {
    return sineMod(angle, 128) * 256 * 256 + sineMod(angle + 120, 128) * 256 + sineMod(angle + 240, 128) + 0x7F7F7F;
}

extern(C) void start() {
    Data data;
    data.time = 0;
    data.x = 0;
    data.y = 0;
    data.rot = 1;
    data.mode = Mode.init;
    setData(data);
}

extern(C) void update() {
    Data data = gameTick();

    bool outline = false;

    final switch (data.mode)
    {
    case Mode.fruit:
        palette[0] = 0xFFF6D3;
        palette[1] = 0xF9A875;
        palette[2] = 0xEb6B6F;
        palette[3] = 0x7C3F58;
        outline = false;
        break;
    case Mode.steel:
        palette[0] = 0xAAAAAA;
        palette[1] = 0x888888;
        palette[2] = 0x555555;
        palette[3] = 0x333333;
        outline = false;
        break;
    case Mode.rgb:
        palette[0] = angleRgb(data.time / 10);
        palette[1] = angleRgb(data.time / 10 + 120);
        palette[2] = angleRgb(data.time / 10 + 240);
        palette[3] = 0xFFFFFF;
        outline = false;
        break;
    case Mode.stop:
        assert(false);
    }

    int n = (data.time % 360 + 360) % 360;
    foreach (i; 0..160) {
        int[2] got = val(i, data.rot, data.pos);
        *drawColors = cast(ushort) (0x44);
        line(i, 0, i, 160);
        *drawColors = cast(ushort) (0x40 + got[0]);
        line(i, 80 - got[1], i, 80 + got[1]);
    }
}
