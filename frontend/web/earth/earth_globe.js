// Realistic 3D Earth Globe using Three.js WebGL & NASA Blue Marble Texture
// Communicates with Flutter Web via PostMessage & same-origin bridge

(function () {
  'use strict';

  let scene, camera, renderer, controls;
  let earthMesh, cloudsMesh, atmosphereMesh;
  let earthGroup;
  let starsMesh;
  const hotelMarkers = [];
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2();

  const GLOBE_RADIUS = 5.0;
  let isAutoRotating = true;
  let lastUserInteraction = Date.now();
  let selectedMarkerId = null;

  // Animation targets for smooth camera / globe focusing
  let isAnimatingTarget = false;
  let targetRotationY = 0;
  let targetRotationX = 0;
  let targetCameraDistance = 13.0;

  const container = document.getElementById('globe-container');
  const tooltip = document.getElementById('hotel-tooltip');
  const tooltipTitle = document.getElementById('tooltip-title');
  const tooltipSub = document.getElementById('tooltip-sub');
  const loadingOverlay = document.getElementById('loading-overlay');

  // Offset variables to shift the Earth towards the right and downwards
  // Keeping it visually centered in the main content area away from the left sidebar
  let globeOffsetX = (window.innerWidth > 800) ? 1.9 : 0.0;
  let globeOffsetY = (window.innerWidth > 800) ? -1.25 : -0.5;

  function init() {
    console.log('[EarthGlobe] Initializing Realistic 3D Earth Scene on Pure Black...');

    // 1. Scene & Camera
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x000000); // Pure Black Background

    camera = new THREE.PerspectiveCamera(
      45,
      container.clientWidth / container.clientHeight,
      0.1,
      1000
    );
    camera.position.set(globeOffsetX, globeOffsetY, 13.0);

    // 2. Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.2;
    container.appendChild(renderer.domElement);
    renderer.domElement.id = 'globe-canvas';

    // 3. OrbitControls centered around the shifted Earth position
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.rotateSpeed = 0.6;
    controls.zoomSpeed = 0.8;
    controls.minDistance = 6.8;
    controls.maxDistance = 22.0;
    controls.enablePan = false;
    controls.target.set(globeOffsetX, globeOffsetY, 0);

    controls.addEventListener('start', onInteractionStart);
    controls.addEventListener('end', onInteractionEnd);

    // 4. Earth Group (holds Earth, clouds, and markers shifted right & down)
    earthGroup = new THREE.Group();
    earthGroup.position.set(globeOffsetX, globeOffsetY, 0);
    scene.add(earthGroup);

    // 5. Lighting (Directional sunlight from top-right + subtle ambient space bounce)
    const sunLight = new THREE.DirectionalLight(0xffffff, 1.45);
    sunLight.position.set(22, 10, 14);
    scene.add(sunLight);

    const ambientLight = new THREE.AmbientLight(0x18243c, 0.4);
    scene.add(ambientLight);

    // 6. Deep Space Starfield with white & subtle electric-blue particles
    createStarfield();

    // 7. Load Textures & Build Meshes
    loadEarthAssets();

    // 8. Event Listeners
    window.addEventListener('resize', onWindowResize);
    window.addEventListener('mousemove', onMouseMove);
    window.addEventListener('click', onMouseClick);
    window.addEventListener('message', handleFlutterMessage);

    // Notify Flutter parent that bridge is ready
    notifyFlutter({ type: 'GLOBE_READY' });

    animate();
  }

  function createStarfield() {
    const starCount = 2400;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(starCount * 3);
    const colors = new Float32Array(starCount * 3);

    for (let i = 0; i < starCount * 3; i += 3) {
      const radius = 60 + Math.random() * 140;
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(Math.random() * 2 - 1);

      positions[i] = radius * Math.sin(phi) * Math.cos(theta);
      positions[i + 1] = radius * Math.sin(phi) * Math.sin(theta);
      positions[i + 2] = radius * Math.cos(phi);

      // 30% subtle electric blue/cyan stars, 70% pure white stars
      if (Math.random() < 0.3) {
        colors[i] = 0.2 + Math.random() * 0.3;
        colors[i + 1] = 0.7 + Math.random() * 0.3;
        colors[i + 2] = 1.0;
      } else {
        const brightness = 0.6 + Math.random() * 0.4;
        colors[i] = brightness;
        colors[i + 1] = brightness;
        colors[i + 2] = brightness;
      }
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    const material = new THREE.PointsMaterial({
      size: 1.1,
      vertexColors: true,
      transparent: true,
      opacity: 0.9
    });

    starsMesh = new THREE.Points(geometry, material);
    scene.add(starsMesh);
  }

  function loadEarthAssets() {
    const textureLoader = new THREE.TextureLoader();

    // Day texture: NASA Blue Marble
    const dayTexture = textureLoader.load(
      '../assets/earth/earth_day_texture.jpg',
      () => {
        console.log('[EarthGlobe] NASA Blue Marble Day Texture Loaded Successfully!');
        if (loadingOverlay) {
          loadingOverlay.style.opacity = '0';
          setTimeout(() => { loadingOverlay.style.display = 'none'; }, 600);
        }
      },
      undefined,
      (err) => {
        console.warn('[EarthGlobe] Could not load local texture, using fallback:', err);
      }
    );

    const normalTexture = textureLoader.load('../assets/earth/earth_normal.jpg');
    const specularTexture = textureLoader.load('../assets/earth/earth_specular.jpg');
    const cloudsTexture = textureLoader.load('../assets/earth/earth_clouds.png');
    const nightTexture = textureLoader.load('../assets/earth/earth_night_lights.png');

    // 1. Earth Sphere with Day Texture + City Night Lights Emissive
    const earthGeometry = new THREE.SphereGeometry(GLOBE_RADIUS, 64, 64);
    const earthMaterial = new THREE.MeshPhongMaterial({
      map: dayTexture,
      normalMap: normalTexture,
      normalScale: new THREE.Vector2(0.85, 0.85),
      specularMap: specularTexture,
      specular: new THREE.Color(0x223355),
      shininess: 18,
    });

    earthMesh = new THREE.Mesh(earthGeometry, earthMaterial);
    earthGroup.add(earthMesh);

    // 2. Realistic Cloud Layer (slowly rotating)
    const cloudsGeometry = new THREE.SphereGeometry(GLOBE_RADIUS + 0.04, 64, 64);
    const cloudsMaterial = new THREE.MeshPhongMaterial({
      map: cloudsTexture,
      transparent: true,
      opacity: 0.38,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });

    cloudsMesh = new THREE.Mesh(cloudsGeometry, cloudsMaterial);
    earthGroup.add(cloudsMesh);

    // 3. Electric Cyan Atmospheric Halo around Earth
    const atmosphereGeometry = new THREE.SphereGeometry(GLOBE_RADIUS + 0.12, 64, 64);
    const atmosphereMaterial = new THREE.ShaderMaterial({
      vertexShader: `
        varying vec3 vNormal;
        void main() {
          vNormal = normalize(normalMatrix * normal);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        varying vec3 vNormal;
        void main() {
          float intensity = pow(0.68 - dot(vNormal, vec3(0, 0, 1.0)), 2.0);
          gl_FragColor = vec4(0.0, 0.82, 1.0, 1.0) * intensity * 1.35;
        }
      `,
      blending: THREE.AdditiveBlending,
      side: THREE.BackSide,
      transparent: true,
    });

    atmosphereMesh = new THREE.Mesh(atmosphereGeometry, atmosphereMaterial);
    atmosphereMesh.position.set(globeOffsetX, globeOffsetY, 0);
    scene.add(atmosphereMesh);

    // Set initial camera view showing Atlantic, Europe, and Africa matching the reference image
    setCoordinatesFocus(20.0, -30.0, false, 13.0);
  }

  // Convert Latitude & Longitude to 3D Cartesian coordinates on sphere
  function latLngToVector3(lat, lng, radius) {
    const phi = (90 - lat) * (Math.PI / 180);
    const theta = (lng + 180) * (Math.PI / 180);

    const x = -(radius * Math.sin(phi) * Math.cos(theta));
    const z = (radius * Math.sin(phi) * Math.sin(theta));
    const y = (radius * Math.cos(phi));

    return new THREE.Vector3(x, y, z);
  }

  // Calculate target rotation to bring (lat, lng) directly in front of the camera
  function getTargetRotation(lat, lng) {
    const rotY = -(lng * Math.PI / 180) - (Math.PI / 2);
    const rotX = (lat * Math.PI / 180);
    return { rotX, rotY };
  }

  function setCoordinatesFocus(lat, lng, animate = true, zoomDistance = 8.6) {
    console.log(`[EarthGlobe] Focusing coordinates: lat=${lat}, lng=${lng}, animate=${animate}`);
    const targets = getTargetRotation(lat, lng);
    targetRotationY = targets.rotY;
    targetRotationX = targets.rotX;
    targetCameraDistance = zoomDistance;

    if (!animate) {
      earthGroup.rotation.y = targetRotationY;
      earthGroup.rotation.x = targetRotationX;
      camera.position.set(globeOffsetX, globeOffsetY, targetCameraDistance);
      controls.target.set(globeOffsetX, globeOffsetY, 0);
    } else {
      isAnimatingTarget = true;
      isAutoRotating = false;
      lastUserInteraction = Date.now();
    }
  }

  // Cached procedural glowing dot textures for optimal WebGL performance
  let cyanGlowTexture = null;
  let goldGlowTexture = null;

  function getCyanGlowTexture() {
    if (cyanGlowTexture) return cyanGlowTexture;
    const canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    const ctx = canvas.getContext('2d');

    const gradient = ctx.createRadialGradient(64, 64, 0, 64, 64, 64);
    gradient.addColorStop(0.0, 'rgba(255, 255, 255, 1.0)');
    gradient.addColorStop(0.18, 'rgba(0, 240, 255, 0.95)');
    gradient.addColorStop(0.45, 'rgba(0, 210, 255, 0.55)');
    gradient.addColorStop(0.75, 'rgba(0, 160, 255, 0.18)');
    gradient.addColorStop(1.0, 'rgba(0, 140, 255, 0.0)');

    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 128, 128);

    cyanGlowTexture = new THREE.CanvasTexture(canvas);
    return cyanGlowTexture;
  }

  function getGoldGlowTexture() {
    if (goldGlowTexture) return goldGlowTexture;
    const canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    const ctx = canvas.getContext('2d');

    const gradient = ctx.createRadialGradient(64, 64, 0, 64, 64, 64);
    gradient.addColorStop(0.0, 'rgba(255, 255, 255, 1.0)');
    gradient.addColorStop(0.18, 'rgba(255, 215, 0, 0.95)');
    gradient.addColorStop(0.45, 'rgba(245, 158, 11, 0.55)');
    gradient.addColorStop(0.75, 'rgba(217, 119, 6, 0.18)');
    gradient.addColorStop(1.0, 'rgba(180, 83, 9, 0.0)');

    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, 128, 128);

    goldGlowTexture = new THREE.CanvasTexture(canvas);
    return goldGlowTexture;
  }

  // Render small, glowing circular cyan dots on the Earth surface for each hotel
  // 1 Hotel = 1 Small Cyan Dot with Subtle Outer Glow (Exactly matches reference image)
  function renderHotelMarkers(hotelsList) {
    console.log(`[EarthGlobe] Rendering ${hotelsList.length} small cyan hotel dots on globe surface...`);
    clearHotelMarkers();

    if (!hotelsList || hotelsList.length === 0) {
      console.log('[EarthGlobe] Zero hotels provided. Globe cleared.');
      return;
    }

    const placedCoords = [];

    hotelsList.forEach((hotel, idx) => {
      let lat = parseFloat(hotel.latitude);
      let lng = parseFloat(hotel.longitude);

      if (isNaN(lat) || isNaN(lng)) return;

      // Check for extremely close proximity with already placed hotels (< 0.003 deg)
      // and apply a micro visual spiderfy tangent offset so both dots remain distinct and clickable
      let offsetLat = 0;
      let offsetLng = 0;
      for (let i = 0; i < placedCoords.length; i++) {
        const dLat = Math.abs(placedCoords[i].lat - lat);
        const dLng = Math.abs(placedCoords[i].lng - lng);
        if (dLat < 0.0035 && dLng < 0.0035) {
          const angle = (idx * 1.618033) * Math.PI * 2;
          offsetLat = Math.sin(angle) * 0.004;
          offsetLng = Math.cos(angle) * 0.004;
          break;
        }
      }
      placedCoords.push({ lat: lat, lng: lng });

      const surfaceRadius = GLOBE_RADIUS + 0.025;
      const pos = latLngToVector3(lat + offsetLat, lng + offsetLng, surfaceRadius);

      // Marker container attached to earthGroup so it rotates glued to Earth
      const markerGroup = new THREE.Group();
      markerGroup.position.copy(pos);

      // Orient marker along the surface normal
      const normal = pos.clone().normalize();
      markerGroup.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), normal);

      // 1. Small Circular Cyan Dot (Surface Dot, Radius 0.045)
      const dotGeometry = new THREE.SphereGeometry(0.045, 16, 16);
      const dotMaterial = new THREE.MeshBasicMaterial({
        color: 0x00F0FF,
        depthTest: true,
        depthWrite: true
      });
      const dotMesh = new THREE.Mesh(dotGeometry, dotMaterial);
      markerGroup.add(dotMesh);

      // 2. Subtle Outer Radial Glow Billboard Sprite (Electric Cyan Halo)
      const glowMaterial = new THREE.SpriteMaterial({
        map: getCyanGlowTexture(),
        color: 0x00F0FF,
        transparent: true,
        opacity: 0.88,
        blending: THREE.AdditiveBlending,
        depthTest: true,
        depthWrite: false
      });
      const glowSprite = new THREE.Sprite(glowMaterial);
      const baseScale = 0.22;
      glowSprite.scale.set(baseScale, baseScale, 1.0);
      markerGroup.add(glowSprite);

      // 3. Invisible Hit Proxy for Smooth, Reliable Mouse Clicking
      const hitGeometry = new THREE.SphereGeometry(0.09, 8, 8);
      const hitMaterial = new THREE.MeshBasicMaterial({ visible: false });
      const hitMesh = new THREE.Mesh(hitGeometry, hitMaterial);
      markerGroup.add(hitMesh);

      // Store metadata
      markerGroup.userData = {
        hotel: hotel,
        hotelId: hotel.hotel_id,
        isHotelMarker: true,
        dotMesh: dotMesh,
        glowSprite: glowSprite,
        hitMesh: hitMesh,
        pulsePhase: (idx * 0.75) % (Math.PI * 2),
        baseScale: baseScale
      };
      hitMesh.userData = markerGroup.userData;
      dotMesh.userData = markerGroup.userData;

      earthGroup.add(markerGroup);
      hotelMarkers.push(markerGroup);
    });

    console.log(`[EarthGlobe] Successfully rendered ${hotelMarkers.length} small cyan hotel dots.`);
  }

  function clearHotelMarkers() {
    hotelMarkers.forEach((marker) => {
      earthGroup.remove(marker);
    });
    hotelMarkers.length = 0;
    selectedMarkerId = null;
    hoveredMarker = null;
    hideTooltip();
  }

  function selectHotelMarker(hotelId) {
    selectedMarkerId = hotelId;
    hotelMarkers.forEach((m) => {
      const isSelected = (m.userData.hotelId === hotelId);
      if (m.userData.dotMesh) {
        m.userData.dotMesh.material.color.setHex(isSelected ? 0xFFD700 : 0x00F0FF);
      }
      if (m.userData.glowSprite) {
        m.userData.glowSprite.material.map = isSelected ? getGoldGlowTexture() : getCyanGlowTexture();
        m.userData.glowSprite.material.color.setHex(isSelected ? 0xFBBF24 : 0x00F0FF);
        const selScale = isSelected ? 0.32 : m.userData.baseScale;
        m.userData.glowSprite.scale.set(selScale, selScale, 1.0);
      }
    });
  }

  function onInteractionStart() {
    isAutoRotating = false;
    isAnimatingTarget = false;
    lastUserInteraction = Date.now();
  }

  function onInteractionEnd() {
    lastUserInteraction = Date.now();
  }

  let hoveredMarker = null;

  function onMouseMove(event) {
    const rect = renderer.domElement.getBoundingClientRect();
    mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);

    // Only test markers that are on the visible side of the Earth
    const clickableObjects = [];
    hotelMarkers.forEach((m) => {
      if (m.visible && m.userData.hitMesh) {
        clickableObjects.push(m.userData.hitMesh);
      }
    });

    const intersects = raycaster.intersectObjects(clickableObjects);

    if (intersects.length > 0) {
      const hit = intersects[0];
      const m = hit.object.parent;
      const hotel = m.userData.hotel;
      if (hotel) {
        renderer.domElement.style.cursor = 'pointer';
        showTooltip(event.clientX, event.clientY, hotel);

        if (hoveredMarker !== m) {
          if (hoveredMarker && hoveredMarker.userData.hotelId !== selectedMarkerId) {
            hoveredMarker.userData.glowSprite.scale.set(
              hoveredMarker.userData.baseScale,
              hoveredMarker.userData.baseScale,
              1.0
            );
          }
          hoveredMarker = m;
          const hovScale = m.userData.hotelId === selectedMarkerId ? 0.36 : 0.30;
          m.userData.glowSprite.scale.set(hovScale, hovScale, 1.0);
        }
        return;
      }
    }

    if (hoveredMarker) {
      if (hoveredMarker.userData.hotelId !== selectedMarkerId) {
        hoveredMarker.userData.glowSprite.scale.set(
          hoveredMarker.userData.baseScale,
          hoveredMarker.userData.baseScale,
          1.0
        );
      }
      hoveredMarker = null;
    }

    renderer.domElement.style.cursor = 'grab';
    hideTooltip();
  }

  function onMouseClick(event) {
    const rect = renderer.domElement.getBoundingClientRect();
    mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);

    // Only clickable if visible on the front-facing hemisphere of Earth
    const clickableObjects = [];
    hotelMarkers.forEach((m) => {
      if (m.visible && m.userData.hitMesh) {
        clickableObjects.push(m.userData.hitMesh);
      }
    });

    const intersects = raycaster.intersectObjects(clickableObjects);

    if (intersects.length > 0) {
      const hit = intersects[0];
      const m = hit.object.parent;
      const hotel = m.userData.hotel;
      if (hotel) {
        console.log(`[EarthGlobe] Hotel dot clicked: ${hotel.hotel_name} (ID: ${hotel.hotel_id})`);
        selectHotelMarker(hotel.hotel_id);

        // Send event to Flutter parent
        notifyFlutter({
          type: 'HOTEL_CLICKED',
          hotelId: hotel.hotel_id,
          hotel: hotel
        });
      }
    }
  }

  function showTooltip(x, y, hotel) {
    if (!tooltip) return;
    tooltipTitle.textContent = hotel.hotel_name || 'Luxury Hotel';
    tooltipSub.textContent = `$${parseFloat(hotel.starting_price || 240).toFixed(0)}/night • ★ ${parseFloat(hotel.star_rating || 4.5).toFixed(1)}`;
    tooltip.style.left = `${x}px`;
    tooltip.style.top = `${y - 12}px`;
    tooltip.style.display = 'block';
  }

  function hideTooltip() {
    if (tooltip) tooltip.style.display = 'none';
  }

  // Handle incoming commands from Flutter Web
  function handleFlutterMessage(event) {
    let data = event.data;
    if (typeof data === 'string') {
      try {
        data = JSON.parse(data);
      } catch (e) {
        return;
      }
    }
    if (!data || typeof data !== 'object') return;

    console.log('[EarthGlobe] Received message from Flutter:', data.type);

    switch (data.type) {
      case 'FOCUS_COORDINATES':
        if (data.latitude !== undefined && data.longitude !== undefined) {
          setCoordinatesFocus(
            parseFloat(data.latitude),
            parseFloat(data.longitude),
            data.animate !== false,
            data.zoom || 8.6
          );
        }
        break;

      case 'SET_HOTELS':
        if (Array.isArray(data.hotels)) {
          renderHotelMarkers(data.hotels);
        }
        break;

      case 'SELECT_HOTEL':
        if (data.hotelId !== undefined) {
          selectHotelMarker(data.hotelId);
        }
        break;

      case 'CLEAR_HOTELS':
        clearHotelMarkers();
        break;

      case 'TOGGLE_AUTO_ROTATE':
        isAutoRotating = !!data.enabled;
        break;

      case 'RESET_VIEW':
        setCoordinatesFocus(20.0, -30.0, true, 13.0);
        isAutoRotating = true;
        break;

      case 'SET_BLUR':
        if (data.blurred) {
          container.style.filter = 'blur(10px)';
          container.style.transition = 'filter 0.3s ease';
        } else {
          container.style.filter = 'none';
        }
        break;
    }
  }

  function notifyFlutter(payload) {
    if (window.parent && window.parent !== window) {
      window.parent.postMessage(JSON.stringify(payload), '*');
    }
  }

  function onWindowResize() {
    if (!camera || !renderer) return;
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);

    globeOffsetX = (container.clientWidth > 800) ? 1.9 : 0.0;
    globeOffsetY = (container.clientWidth > 800) ? -1.25 : -0.5;
    if (earthGroup) earthGroup.position.set(globeOffsetX, globeOffsetY, 0);
    if (atmosphereMesh) atmosphereMesh.position.set(globeOffsetX, globeOffsetY, 0);
    if (controls) controls.target.set(globeOffsetX, globeOffsetY, 0);
  }

  // Render loop
  function animate() {
    requestAnimationFrame(animate);

    // 1. Gentle Cloud Drift
    if (cloudsMesh) {
      cloudsMesh.rotation.y += 0.0007;
    }

    // 2. Smooth Focus Transition
    if (isAnimatingTarget && earthGroup) {
      // Normalize angle difference
      let diffY = targetRotationY - earthGroup.rotation.y;
      while (diffY < -Math.PI) diffY += Math.PI * 2;
      while (diffY > Math.PI) diffY -= Math.PI * 2;

      let diffX = targetRotationX - earthGroup.rotation.x;

      if (Math.abs(diffY) > 0.005 || Math.abs(diffX) > 0.005) {
        earthGroup.rotation.y += diffY * 0.07;
        earthGroup.rotation.x += diffX * 0.07;
      } else {
        earthGroup.rotation.y = targetRotationY;
        earthGroup.rotation.x = targetRotationX;
        isAnimatingTarget = false;
      }

      // Smooth camera zoom
      const distDiff = targetCameraDistance - camera.position.z;
      if (Math.abs(distDiff) > 0.05) {
        camera.position.z += distDiff * 0.08;
      }

      camera.position.x = globeOffsetX;
      camera.position.y = globeOffsetY;
      controls.target.set(globeOffsetX, globeOffsetY, 0);
    }
    // 3. Auto-rotation when idle
    else if (isAutoRotating && Date.now() - lastUserInteraction > 2500) {
      if (earthGroup) {
        earthGroup.rotation.y += 0.0016;
      }
    }

    // 4. Update hotel markers: Back-of-globe occlusion and subtle breathing glow
    const cameraWorldDir = camera.position.clone().sub(earthGroup.position).normalize();
    const tempMarkerPos = new THREE.Vector3();
    const timeNow = Date.now() * 0.003;

    hotelMarkers.forEach((m) => {
      m.getWorldPosition(tempMarkerPos);
      const markerDir = tempMarkerPos.clone().sub(earthGroup.position).normalize();
      const dot = markerDir.dot(cameraWorldDir);

      // Markers on the back of the globe (facing away from camera) are hidden
      // Markers on visible side (dot > 0.03) remain visible and clickable
      if (dot <= 0.03) {
        m.visible = false;
        if (hoveredMarker === m) {
          hideTooltip();
          hoveredMarker = null;
        }
      } else {
        m.visible = true;
        // Subtle breathing pulse on the outer cyan glow when idle
        if (m.userData.glowSprite && m !== hoveredMarker && m.userData.hotelId !== selectedMarkerId) {
          const pulse = 1.0 + 0.08 * Math.sin(timeNow + (m.userData.pulsePhase || 0));
          const s = m.userData.baseScale * pulse;
          m.userData.glowSprite.scale.set(s, s, 1.0);
        }
      }
    });

    controls.update();
    renderer.render(scene, camera);
  }

  // Initialize once DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
