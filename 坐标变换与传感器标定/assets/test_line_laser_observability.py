"""Geometric regression tests for the two dependency-free teaching demos."""

import math
import unittest

import line_laser_height_observability as height_demo
import line_laser_pitch_observability as pitch_demo


class PitchObservabilityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.points = pitch_demo.make_data()

    def test_each_station_observes_both_shared_walls(self):
        for station in range(len(pitch_demo.POSES)):
            for wall in ("A", "B"):
                support = sum(
                    point["station"] == station and point["wall"] == wall
                    for point in self.points
                )
                self.assertGreaterEqual(support, 5)

    def test_wrong_pitch_fits_one_station_but_not_shared_walls(self):
        self.assertLess(
            pitch_demo.wall_rms(self.points, pitch_demo.WRONG_PITCH, multi=False),
            1e-10,
        )
        self.assertGreater(
            pitch_demo.wall_rms(self.points, pitch_demo.WRONG_PITCH, multi=True),
            0.001,
        )

    def test_ground_constraint_leaves_height_pitch_family(self):
        for beta in (pitch_demo.TRUE_PITCH, pitch_demo.WRONG_PITCH, math.radians(40)):
            height = pitch_demo.GROUND_C * math.sin(beta)
            for theta in (-0.9, 0.0, 0.9):
                ray_range = pitch_demo.GROUND_C / math.cos(theta)
                z = height - ray_range * math.cos(theta) * math.sin(beta)
                self.assertAlmostEqual(z, 0.0, places=12)


class HeightRecoveryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.points = pitch_demo.make_data()

    def test_height_search_recovers_synthetic_scene(self):
        estimate = height_demo.solve_height(self.points, pitch_demo.GROUND_C)
        self.assertAlmostEqual(estimate, pitch_demo.HEIGHT, delta=1e-8)

    def test_independent_height_blocks_are_not_part_of_fit(self):
        estimate = height_demo.solve_height(self.points, pitch_demo.GROUND_C)
        for expected_height in (0.030, 0.050):
            qx = pitch_demo.GROUND_C * (1 - expected_height / pitch_demo.HEIGHT)
            measured = estimate - qx * estimate / pitch_demo.GROUND_C
            self.assertAlmostEqual(measured, expected_height, delta=1e-8)


if __name__ == "__main__":
    unittest.main()
