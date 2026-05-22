import React, { Suspense, useMemo, useRef, useState, useEffect } from 'react';
import { Canvas, useFrame, useLoader } from '@react-three/fiber';
import { OrbitControls, Html } from '@react-three/drei';
import * as THREE from 'three';

const FRONT_SRC = '/tshirt/front.png';
const BACK_SRC = '/tshirt/back.png';

const SIZES = ['S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

// Plane width in world units. Height derived from image aspect (435x575).
const SHIRT_WIDTH = 3.0;
const SHIRT_HEIGHT = SHIRT_WIDTH * (575 / 435);

// Tiny gap between the two planes so z-fighting doesn't shimmer along the edge.
const PLANE_GAP = 0.01;

function ShirtMesh({ autoRotate, selectedSize }) {
  const groupRef = useRef();
  const [frontTex, backTex] = useLoader(THREE.TextureLoader, [FRONT_SRC, BACK_SRC]);

  // Tighter color reproduction + crisp transparent edges.
  useMemo(() => {
    [frontTex, backTex].forEach((t) => {
      t.colorSpace = THREE.SRGBColorSpace;
      t.anisotropy = 8;
      t.minFilter = THREE.LinearMipMapLinearFilter;
      t.magFilter = THREE.LinearFilter;
    });
  }, [frontTex, backTex]);

  useFrame((_, delta) => {
    if (autoRotate && groupRef.current) {
      groupRef.current.rotation.y += delta * 0.35;
    }
  });

  return (
    <group ref={groupRef}>
      {/* Front face — looking down +Z */}
      <mesh position={[0, 0, PLANE_GAP / 2]}>
        <planeGeometry args={[SHIRT_WIDTH, SHIRT_HEIGHT]} />
        <meshStandardMaterial
          map={frontTex}
          transparent
          alphaTest={0.05}
          side={THREE.FrontSide}
          roughness={0.85}
          metalness={0.02}
        />
      </mesh>

      {/* Back face — flipped 180° so it shows correctly when you rotate around */}
      <mesh position={[0, 0, -PLANE_GAP / 2]} rotation={[0, Math.PI, 0]}>
        <planeGeometry args={[SHIRT_WIDTH, SHIRT_HEIGHT]} />
        <meshStandardMaterial
          map={backTex}
          transparent
          alphaTest={0.05}
          side={THREE.FrontSide}
          roughness={0.85}
          metalness={0.02}
        />
      </mesh>

      {/* Selected-size badge floats above the shirt */}
      {selectedSize && (
        <Html
          center
          position={[0, SHIRT_HEIGHT / 2 + 0.45, 0]}
          distanceFactor={6}
          zIndexRange={[10, 0]}
          style={{ pointerEvents: 'none' }}
        >
          <div
            style={{
              background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
              color: '#0f172a',
              padding: '8px 18px',
              borderRadius: 999,
              fontWeight: 800,
              fontSize: 14,
              letterSpacing: 1,
              boxShadow: '0 6px 18px rgba(245, 158, 11, 0.45)',
              border: '2px solid #fff',
              whiteSpace: 'nowrap',
            }}
          >
            SIZE {selectedSize}
          </div>
        </Html>
      )}
    </group>
  );
}

function SceneFallback() {
  return (
    <Html center>
      <div style={{ color: '#cbd5e1', fontSize: 14 }}>Loading shirt…</div>
    </Html>
  );
}

/**
 * 3D T-shirt picker. Drag to rotate; pinch to zoom.
 * Auto-rotates until the user starts dragging.
 */
export default function TshirtPicker3D({ value, onChange, disabled }) {
  const [autoRotate, setAutoRotate] = useState(true);

  // Stop auto-rotate the first time the user interacts with the canvas.
  useEffect(() => {
    if (!autoRotate) return undefined;
    const stop = () => setAutoRotate(false);
    window.addEventListener('pointerdown', stop, { once: true });
    return () => window.removeEventListener('pointerdown', stop);
  }, [autoRotate]);

  return (
    <div
      style={{
        background: 'linear-gradient(180deg, #0f172a 0%, #1e293b 100%)',
        borderRadius: 24,
        padding: 24,
        boxShadow: '0 25px 60px rgba(0,0,0,0.3)',
        border: '1px solid rgba(245, 158, 11, 0.2)',
      }}
    >
      <div
        style={{
          height: 420,
          borderRadius: 16,
          overflow: 'hidden',
          background: 'radial-gradient(ellipse at center, #1e3a8a 0%, #0f172a 70%)',
          position: 'relative',
        }}
      >
        <Canvas
          camera={{ position: [0, 0, 6], fov: 35 }}
          dpr={[1, 2]}
          gl={{ antialias: true, alpha: true }}
        >
          <ambientLight intensity={0.85} />
          <directionalLight position={[3, 5, 5]} intensity={0.8} />
          <directionalLight position={[-3, 2, -3]} intensity={0.3} color="#fbbf24" />

          <Suspense fallback={<SceneFallback />}>
            <ShirtMesh autoRotate={autoRotate} selectedSize={value} />
          </Suspense>

          <OrbitControls
            enablePan={false}
            enableZoom
            minDistance={4}
            maxDistance={9}
            minPolarAngle={Math.PI / 2.4}
            maxPolarAngle={Math.PI / 1.7}
          />
        </Canvas>

        <div
          style={{
            position: 'absolute',
            bottom: 12,
            left: 0,
            right: 0,
            textAlign: 'center',
            color: '#cbd5e1',
            fontSize: 11,
            letterSpacing: 1,
            textTransform: 'uppercase',
            opacity: 0.7,
            pointerEvents: 'none',
          }}
        >
          Drag to rotate · scroll to zoom
        </div>
      </div>

      <div
        style={{
          marginTop: 22,
          display: 'grid',
          gridTemplateColumns: 'repeat(6, 1fr)',
          gap: 8,
        }}
      >
        {SIZES.map((s) => {
          const active = s === value;
          return (
            <button
              key={s}
              type="button"
              onClick={() => !disabled && onChange(s)}
              disabled={disabled}
              style={{
                padding: '12px 0',
                fontSize: 15,
                fontWeight: 800,
                letterSpacing: 0.5,
                background: active
                  ? 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)'
                  : 'rgba(15, 23, 42, 0.6)',
                color: active ? '#0f172a' : '#e2e8f0',
                border: active ? '2px solid #fbbf24' : '1px solid rgba(245,158,11,0.25)',
                borderRadius: 12,
                cursor: disabled ? 'not-allowed' : 'pointer',
                opacity: disabled ? 0.5 : 1,
                transition: 'transform 0.15s, box-shadow 0.15s',
                boxShadow: active ? '0 4px 14px rgba(245,158,11,0.4)' : 'none',
              }}
              onMouseEnter={(e) => { if (!active && !disabled) e.currentTarget.style.background = 'rgba(245,158,11,0.12)'; }}
              onMouseLeave={(e) => { if (!active && !disabled) e.currentTarget.style.background = 'rgba(15, 23, 42, 0.6)'; }}
            >
              {s}
            </button>
          );
        })}
      </div>
    </div>
  );
}
