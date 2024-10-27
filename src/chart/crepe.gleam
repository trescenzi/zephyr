pub type Scale =
  fn(Float) -> Float

pub type ChartConfig {
  Config(scale: Scale)
}

fn scale(range_0: Float, domain_0: Float, slope: Float, num: Float) -> Float {
  todo
}

pub fn build_linear_scale(
  domain: Tuple(Float, Float),
  range: Tuple(Float, Float),
) -> Scale {
  let d0 = tuple.first(domain)
  let d1 = tuple.second(domain)
  let r0 = tuple.first(range)
  let r1 = tuple.second(range)
  let m = { r1 - r0 } / { d1 -. d0 }

  scale(r0, d0, m, _)
}
