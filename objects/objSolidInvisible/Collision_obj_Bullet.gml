spark = random(2)
if (spark == 2){
effect_create_layer("ParticleLayer",ef_smoke, other.x, other.y,.5, c_grey);
effect_create_layer("ParticleLayer",ef_spark, other.x, other.y,.5, c_orange);
}
instance_destroy(other)
