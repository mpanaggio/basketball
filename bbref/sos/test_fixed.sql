select pl.parameter,pl.type,pl.level,bf.estimate
from bbref._parameter_levels pl
left outer join bbref._basic_factors bf
  on (bf.factor,bf.type)=(pl.parameter||pl.level,pl.type)
where pl.type='fixed'
order by parameter,level;
