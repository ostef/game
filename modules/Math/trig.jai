#import "Linalg";

Semi_Circle_Iterator :: struct
{
	start_angle : f32;
	angle : f32;
	resolution : s64;
}

semi_circle :: inline (start_angle : f32, angle : f32, resolution : s64) -> Semi_Circle_Iterator #must
{
	result : Semi_Circle_Iterator = ---;
	result.start_angle = start_angle;
	result.angle = angle;
	result.resolution = resolution;

	return result;
}

circle :: inline (resolution : s64) -> Semi_Circle_Iterator #must
{
	return semi_circle (0, 2 * PI, resolution);
}

for_expansion :: (iter : *Semi_Circle_Iterator, body : Code, flags : For_Flags) #expand
{
	theta := iter.angle / cast (f32) iter.resolution;
	tan_factor := tan (theta);
	rad_factor := cos (theta);
	`it := vec2f (cos (iter.start_angle), sin (iter.start_angle));
	for `it_index : 0..iter.resolution - 1
	{
		defer {
			t := vec2f (-it.y, it.x);
			it += t * tan_factor;
			it *= rad_factor;
		}
		#insert body;
	}
}
