shader_type spatial;
uniform vec4 tint : source_color = vec4(.42,.44,.36,1.0);
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 uv=vec2(world.x+world.z,world.y);
 float row=floor(uv.y/.42);
 uv.x+=mod(row,2.0)*.5;
 vec2 cell=fract(uv/vec2(.95,.42));
 float mortar=step(.025,cell.x)*step(.04,cell.y);
 float variance=hash(floor(uv/vec2(.95,.42)));
 float grain=hash(floor(uv*160.0));
 ALBEDO=tint.rgb*mix(.48,.78+variance*.3,mortar)*(.93+grain*.12);
 ROUGHNESS=.95;
}
