import networkx as nx
from typing import List, Dict, Tuple
import math

class SolverService:
    def __init__(self):
        pass

    def solve_maze(self, waypoints: List[Dict]) -> List[Dict]:
        """
        MAZE Mode: Respects user order.
        Returns the original list.
        """
        return waypoints

    def solve_tsp(self, waypoints: List[Dict]) -> List[Dict]:
        """
        OPTIMIZED Mode: Greedy Nearest Neighbor Algorithm (for V1).
        
        Note: Real TSP requires Distance Matrix from Google Maps. 
        For this prototype, we use Euclidean distance estimation to save API calls 
        and latency, assuming 'As the crow flies' is a rough proxy for travel time.
        In production, use the Distance Matrix.
        """
        if not waypoints:
            return []
            
        # Start with the first point (assume fixed start for now)
        start_node = waypoints[0]
        unvisited = waypoints[1:]
        path = [start_node]
        
        current_node = start_node
        
        while unvisited:
            nearest_node = None
            min_dist = float('inf')
            
            for node in unvisited:
                dist = self._euclidean_dist(
                    current_node['location'], 
                    node['location']
                )
                if dist < min_dist:
                    min_dist = dist
                    nearest_node = node
            
            # Move to nearest node
            path.append(nearest_node)
            unvisited.remove(nearest_node)
            current_node = nearest_node
            
        return path

    def _euclidean_dist(self, loc1: Dict, loc2: Dict) -> float:
        """
        Calculate approximate distance.
        """
        return math.sqrt(
            (loc1['lat'] - loc2['lat'])**2 + 
            (loc1['lng'] - loc2['lng'])**2
        )
