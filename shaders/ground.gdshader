shader_type spatial;
render_mode diffuse_burley;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float broad=noise(world.xz*.55)*.6+noise(world.xz*1.6)*.28+noise(world.xz*6.0)*.12;
 vec3 moss=mix(vec3(.085,.135,.104),vec3(.18,.235,.145),broad);
 float grain=noise(world.xz*75.0);
 ALBEDO=moss*(.82+grain*.3);
 ROUGHNESS=.96;
}
