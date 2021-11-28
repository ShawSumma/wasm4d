import wasm4;
import lines;
import math;

struct Data {
    int time;
    float x;
    float y;
    int rot;

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

// enum float[2][2][] boxes = [
//     [[3, 5], [3, -5]],
//     [[3, -5], [-5, -5]],
//     [[-5, -5], [-5, 5]],
//     [[-5, 5], [3, 5]],
// ];

enum Type : ubyte {
    none,
    yellow,
    orange,
    striped,
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

Wall[] worldData = [
    Wall(Type.striped, [-4, -4], [-4, 4]),
    Wall(Type.striped, [-4, 4], [4, 4]),
    Wall(Type.striped, [4, 4], [4, -4]),
    Wall(Type.striped, [4, -4], [-4, -4]),
];

float fastInverseSqrt(float number)
{
	long i;
	float x2, y;
	const float threehalfs = 1.5F;

	x2 = number * 0.5F;
	y  = number;
	i  = * cast(int *) &y;                       // evil floating point bit level hacking
	i  = 0x5f3759df - ( i >> 1 );               // what the fuck? 
	y  = * cast(float *) &i;
	y  = y * (threehalfs - (x2 * y * y));   // 1st iteration

	return y;
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

float invDistance(float[2] x, float[2] y) {
    float dx = x[0]-y[0];
    float dy = x[1]-y[1];
    return fastInverseSqrt(dx*dx + dy*dy);
}

float distance(float[2] x, float[2] y) {
    return 1 / invDistance(x, y);
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
            case Type.orange:
                return [2, ret2];
            case Type.yellow:
                return [1, ret2];
            case Type.striped:
                int fromStart = cast(int) distance([cast(float) hit.block.start[0], cast(float) hit.block.start[1]], hit.pos);
                if (fromStart % 2 == 0) {
                    return [2, ret2];
                } else {
                    return [1, ret2];
                }
            }
        }
    }
    return [0, 0];
}

enum fov = 90;
enum viewDist = 32;
enum accuracy = 8;
enum speed = 0.03;

extern(C) void start() {
    Data data;
    data.time = 0;
    data.x = 0;
    data.y = 0;
    data.rot = 1;
    setData(data);
}

extern(C) void update() {
    palette[0] = 0xfff6d3;
    palette[1] = 0xf9a875;
    palette[2] = 0xeb6b6f;
    palette[3] = 0x7c3f58;
    Data oldData = getData;
    Data data = oldData;
    
    ubyte gamepad = *gamepad1;
    if (gamepad & buttonRight) {
        data.rot -= 2;
    }
    if (gamepad & buttonLeft) {
        data.rot += 2;
    }
    if (gamepad & buttonUp) {
        data.x += sine(data.rot) * speed;
        data.y += cosine(data.rot) * speed;
    }
    if (gamepad & buttonDown) {
        data.x -= sine(data.rot) * speed;
        data.y -= cosine(data.rot) * speed;
    }

    if (collides(oldData.pos, data.pos).isHit) {
        data.x = oldData.x;
        data.y = oldData.y;
    }

    data.time += 1;
    setData(data);

    int n = (data.time % 360 + 360) % 360;
    float angle = sine(80 + n);
    foreach (i; 0..160) {
        int[2] got = val(i, data.rot, data.pos);
        *drawColors = cast(ushort) (0x44);
        line(i, 0, i, 80 - got[1]);
        if (got[1] != 0) {
            *drawColors = cast(ushort) (0x40 + got[0]);
            line(i, 80 - got[1], i, 80 + got[1]);
        }
        *drawColors = cast(ushort) (0x44);
        line(i, 80 + got[1], i, 160);
    }
}
