#version 100
precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    gl_FragColor = vec4(color.r, color.g * 0.5, color.b * 0.2, color.a);
}
