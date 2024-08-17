layout(set = 2, binding = 0) uniform textureCube cubemap;
layout(set = 2, binding = 1) uniform sphericalHarmonics
{
	vec3 sh[ 9 ];
};

vec4 lovrmain()
{
	Surface surface;
	initSurface(surface);
	vec3 color = vec3(0);
	// vec3 lightDirection = vec3(-1, -1, -1);
	vec3 lightDirection = vec3(-1.2, -4, -5);
	vec4 lightColorAndBrightness = vec4(1, 1, 1, 2);
	float visibility = 1.;
	color += getLighting(surface, lightDirection, lightColorAndBrightness, visibility);
	color += getIndirectLighting(surface, cubemap, sh);

	return vec4(color, 1);
}