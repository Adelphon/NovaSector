/*/datum/antagonist/space_dragon
	// Overriding the max timer defined in image_7603e5.png
	// We set this to a massive value so the "despawn" condition is effectively never met.
	maxRiftTimer = INFINITY
*/
/datum/antagonist/space_dragon/New()
	..()
	// Alternatively, per the logic mentioned in image_7603e5.png line 15:
	// "If set to -1, does not increment."
	riftTimer = -1
