import { useEffect, useMemo, useState } from "react";
import { useGLTF } from "@react-three/drei";
import * as THREE from "three";

interface CutCubeProps {
    glbUrl: string;
    cutPoints: THREE.Vector3[];
    selectedGeometry: "all" | "geometry1" | "geometry2";
}

const CutCubeModel = ({ glbUrl, cutPoints, selectedGeometry }: CutCubeProps) => {
  const { scene } = useGLTF(glbUrl);
  const [ref1, setRef1] = useState<THREE.Mesh | null>(null);
  const [ref2, setRef2] = useState<THREE.Mesh | null>(null);

  useEffect(() => {
    scene.traverse((object) => {
      if (object instanceof THREE.Mesh) {
        let material = new THREE.MeshBasicMaterial({ color: "white" });

        if (object.name === "Geometry001") {
          material.color.set("#B6FF01");
          setRef1(object); // ref1の更新
        } else if (object.name === "Geometry002") {
          material.color.set("#4689FF");
          setRef2(object); // ref2の更新
        }

        object.material = material;

        // エッジ（線）を追加
        const cutEdges = new THREE.EdgesGeometry(object.geometry, 0.1);
        const cutLineMaterial = new THREE.LineBasicMaterial({ color: 0x000000, linewidth: 3 });
        const cutLine = new THREE.LineSegments(cutEdges, cutLineMaterial);
        object.add(cutLine);
      }
    });
  }, [scene]);

  const spheres = useMemo(() => {
    return cutPoints.map((point, index) => (
      <mesh key={index} position={[point.x, point.y, point.z]}>
        <sphereGeometry args={[0.03, 32, 32]} />
        <meshStandardMaterial color="#FF3333" />
      </mesh>
    ));
  }, [cutPoints]);

  console.log("ref1",ref1, "ref2",ref2);

  return (
    <group>
      {spheres}
      <primitive object={scene} />
      {selectedGeometry === "all" || selectedGeometry === "geometry1" ? (
        ref1 && <primitive object={ref1} /> // ref1がnullでない場合のみ表示
      ) : null}
      {selectedGeometry === "all" || selectedGeometry === "geometry2" ? (
        ref2 && <primitive object={ref2} /> // ref2がnullでない場合のみ表示
      ) : null}
    </group>
  );
};

export default CutCubeModel;
