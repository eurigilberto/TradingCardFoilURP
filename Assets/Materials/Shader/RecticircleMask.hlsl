void RecticircleMask_float(float2 size, float2 absPos, float radius, float borderSize, out float Out){
    float vertical = step(absPos.x, (size.x / 2) - radius) * step(absPos.y, (size.y / 2));
    float horizontal = step(absPos.y, (size.y / 2) - radius) * step(absPos.x, (size.x / 2));

    float2 circlePos = float2((size.x / 2) - radius, (size.y / 2) - radius);
    float2 quadrant = float2(absPos.x, absPos.y);

    float dist = distance(circlePos, quadrant);
    float circleMasks = step(dist, radius);
    float mask = saturate(vertical + horizontal + circleMasks);

    Out = mask;
}