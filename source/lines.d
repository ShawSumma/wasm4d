module lines;

import math;

// Given three collinear points p, q, r, the function checks if
// point q lies on line segment 'pr'
bool onSegment(float[2] p, float[2] q, float[2] r)
{
    if (q[0] <= max(p[0], r[0]) && q[0] >= min(p[0], r[0]) &&
        q[1] <= max(p[1], r[1]) && q[1] >= min(p[1], r[1]))
       return true;
 
    return false;
}
 
// To find orientation of ordered triplet (p, q, r).
// The function returns following values
// 0 --> p, q and r are collinear
// 1 --> Clockwise
// 2 --> Counterclockwise
int orientation(float[2] p, float[2] q, float[2] r)
{
    // See https://www.geeksforgeeks.org/orientation-3-ordered-points/
    // for details of below formula.
    float val = (q[1] - p[1]) * (r[0] - q[0]) -
              (q[0] - p[0]) * (r[1] - q[1]);
 
    if (val == 0) return 0;  // collinear
 
    return (val > 0)? 1: 2; // clock or counterclock wise
}
 
// The main function that returns true if line segment 'p1q1'
// and 'p2q2' intersect.
bool intersects(bool edgeCases = false)(float[2] p1, float[2] q1, float[2] p2, float[2] q2)
{
    // Find the four orientations needed for general and
    // special cases
    int o1 = orientation(p1, q1, p2);
    int o2 = orientation(p1, q1, q2);
    int o3 = orientation(p2, q2, p1);
    int o4 = orientation(p2, q2, q1);
 
    // General case
    if (o1 != o2 && o3 != o4)
        return true;
 
    static if (edgeCases) {
        // Special Cases
        // p1, q1 and p2 are collinear and p2 lies on segment p1q1
        if (o1 == 0 && onSegment(p1, p2, q1)) return true;
    
        // p1, q1 and q2 are collinear and q2 lies on segment p1q1
        if (o2 == 0 && onSegment(p1, q2, q1)) return true;
    
        // p2, q2 and p1 are collinear and p1 lies on segment p2q2
        if (o3 == 0 && onSegment(p2, p1, q2)) return true;
    
        // p2, q2 and q1 are collinear and q1 lies on segment p2q2
        if (o4 == 0 && onSegment(p2, q1, q2)) return true;
    }

    return false; // Doesn't fall in any of the above cases
}

float[2] intersectsWhere(float[2] p1, float[2] q1, float[2] p2, float[2] q2) {
    double a1 = q1[1] - p1[1];
    double b1 = p1[0] - q1[0];
    double c1 = a1*(p1[0]) + b1*(p1[1]);
    double a2 = q2[1] - p2[1];
    double b2 = p2[0] - q2[0];
    double c2 = a2*(p2[0])+ b2*(p2[1]);
    double determinant = a1*b2 - a2*b1;
    if (determinant == 0) {
         return [float.max, float.max];
    } else {
        double x = (b2*c1 - b1*c2)/determinant;
        double y = (a1*c2 - a2*c1)/determinant;
        return [x, y];
    }
}
