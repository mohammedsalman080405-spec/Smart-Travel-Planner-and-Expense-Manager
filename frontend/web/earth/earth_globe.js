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

  function init() {
    console.log('[EarthGlobe] Initializing Realistic 3D Earth Scene...');

    // 1. Scene & Camera
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x080E1E);

    camera = new THREE.PerspectiveCamera(
      45,
      container.clientWidth / container.clientHeight,
      0.1,
      1000
    );
    camera.position.set(0, 0, 13.0);

    // 2. Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.15;
    container.appendChild(renderer.domElement);
    renderer.domElement.id = 'globe-canvas';

    // 3. OrbitControls
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.rotateSpeed = 0.6;
    controls.zoomSpeed = 0.8;
    controls.minDistance = 6.8;
    controls.maxDistance = 22.0;
    controls.enablePan = false;

    controls.addEventListener('start', onInteractionStart);
    controls.addEventListener('end', onInteractionEnd);

    // 4. Earth Group (holds Earth, clouds, atmosphere and markers)
    earthGroup = new THREE.Group();
    scene.add(earthGroup);

    // 5. Lighting
    // Directional sunlight (Simulating sun illuminating Earth)
    const sunLight = new THREE.DirectionalLight(0xffffff, 1.4);
    sunLight.position.set(20, 8, 12);
    scene.add(sunLight);

    // Ambient space lighting (subtle navy bounce so dark side is visible)
    const ambientLight = new THREE.AmbientLight(0x223558, 0.45);
    scene.add(ambientLight);

    // 6. Deep Space Starfield
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
    const starCount = 1800;
    const geometry = new THREE.BufferGeometry();
    const positions = new Float32Array(starCount * 3);
    const colors = new Float32Array(starCount * 3);

    for (let i = 0; i < starCount * 3; i += 3) {
      const radius = 60 + Math.random() * 120;
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(Math.random() * 2 - 1);

      positions[i] = radius * Math.sin(phi) * Math.cos(theta);
      positions[i + 1] = radius * Math.sin(phi) * Math.sin(theta);
      positions[i + 2] = radius * Math.cos(phi);

      const brightness = 0.4 + Math.random() * 0.6;
      colors[i] = brightness;
      colors[i + 1] = brightness * 0.95;
      colors[i + 2] = brightness;
    }

    geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    const material = new THREE.PointsMaterial({
      size: 0.8,
      vertexColors: true,
      transparent: true,
      opacity: 0.85
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

    // 1. Earth Sphere
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

    // 2. Realistic Cloud Layer (slightly larger sphere, slowly rotating)
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

    // 3. Subtle Atmospheric Glow Halo
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
          float intensity = pow(0.68 - dot(vNormal, vec3(0, 0, 1.0)), 2.2);
          gl_FragColor = vec4(0.0, 0.72, 1.0, 1.0) * intensity;
        }
      `,
      blending: THREE.AdditiveBlending,
      side: THREE.BackSide,
      transparent: true,
    });

    atmosphereMesh = new THREE.Mesh(atmosphereGeometry, atmosphereMaterial);
    scene.add(atmosphereMesh);

    // Set initial camera focus towards India / Central Asia
    setCoordinatesFocus(17.385044, 78.486671, false, 13.0);
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

  function setCoordinatesFocus(lat, lng, animate = true, zoomDistance = 9.5) {
    console.log(`[EarthGlobe] Focusing coordinates: lat=${lat}, lng=${lng}, animate=${animate}`);
    const targets = getTargetRotation(lat, lng);
    targetRotationY = targets.rotY;
    targetRotationX = targets.rotX;
    targetCameraDistance = zoomDistance;

    if (!animate) {
      earthGroup.rotation.y = targetRotationY;
      earthGroup.rotation.x = targetRotationX;
      camera.position.set(0, 0, targetCameraDistance);
    } else {
      isAnimatingTarget = true;
      isAutoRotating = false;
      lastUserInteraction = Date.now();
    }
  }

  // Render small visible dots on the Earth surface for each hotel
  function renderHotelMarkers(hotelsList) {
    console.log(`[EarthGlobe] Rendering ${hotelsList.length} hotel markers on globe surface...`);
    clearHotelMarkers();

    if (!hotelsList || hotelsList.length === 0) {
      console.log('[EarthGlobe] Zero hotels provided. Globe cleared.');
      return;
    }

    hotelsList.forEach((hotel, idx) => {
      const lat = parseFloat(hotel.latitude);
      const lng = parseFloat(hotel.longitude);

      if (isNaN(lat) || isNaN(lng)) return;

      const surfaceRadius = GLOBE_RADIUS + 0.05;
      const pos = latLngToVector3(lat, lng, surfaceRadius);

      // Marker container attached to earthGroup so it stays glued to Earth
      const markerGroup = new THREE.Group();
      markerGroup.position.copy(pos);

      // Orient marker so it points outwards along the sphere normal
      markerGroup.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), pos.clone().normalize());

      // 1. Base glowing dot on sphere surface
      const dotGeometry = new THREE.SphereGeometry(0.08, 16, 16);
      const dotMaterial = new THREE.MeshBasicMaterial({ color: 0x00F0FF });
      const dotMesh = new THREE.Mesh(dotGeometry, dotMaterial);
      markerGroup.add(dotMesh);

      // 2. Vertical Pin Stem
      const stemGeometry = new THREE.CylinderGeometry(0.015, 0.015, 0.28, 8);
      const stemMaterial = new THREE.MeshBasicMaterial({ color: 0x00D2FF });
      const stemMesh = new THREE.Mesh(stemGeometry, stemMaterial);
      stemMesh.position.y = 0.14;
      markerGroup.add(stemMesh);

      // 3. Glowing Pin Head Badge
      const headGeometry = new THREE.SphereGeometry(0.12, 16, 16);
      const headMaterial = new THREE.MeshStandardMaterial({
        color: 0x00D2FF,
        emissive: 0x00F0FF,
        emissiveIntensity: 0.8,
        roughness: 0.2
      });
      const headMesh = new THREE.Mesh(headGeometry, headMaterial);
      headMesh.position.y = 0.32;
      markerGroup.add(headMesh);

      // 4. Ground Pulsing Ripple Ring
      const ringGeometry = new THREE.RingGeometry(0.09, 0.16, 24);
      const ringMaterial = new THREE.MeshBasicMaterial({
        color: 0x00F0FF,
        side: THREE.DoubleSide,
        transparent: true,
        opacity: 0.7
      });
      const ringMesh = new THREE.Mesh(ringGeometry, ringMaterial);
      ringMesh.rotation.x = Math.PI / 2;
      markerGroup.add(ringMesh);

      // Store hotel metadata on the marker group and children for raycasting
      markerGroup.userData = {
        hotel: hotel,
        hotelId: hotel.hotel_id,
        isHotelMarker: true,
        ringMesh: ringMesh,
        headMesh: headMesh,
        pulseVal: Math.random() * Math.PI
      };
      headMesh.userData = markerGroup.userData;
      dotMesh.userData = markerGroup.userData;

      earthGroup.add(markerGroup);
      hotelMarkers.push(markerGroup);
    });

    console.log(`[EarthGlobe] Successfully rendered ${hotelMarkers.length} markers.`);
  }

  function clearHotelMarkers() {
    hotelMarkers.forEach((marker) => {
      earthGroup.remove(marker);
    });
    hotelMarkers.length = 0;
    selectedMarkerId = null;
    hideTooltip();
  }

  function selectHotelMarker(hotelId) {
    selectedMarkerId = hotelId;
    hotelMarkers.forEach((m) => {
      const isSelected = m.userData.hotelId === hotelId;
      if (m.userData.headMesh) {
        m.userData.headMesh.material.color.setHex(isSelected ? 0xFBBF24 : 0x00D2FF);
        m.userData.headMesh.material.emissive.setHex(isSelected ? 0xF59E0B : 0x00F0FF);
      }
      if (isSelected) {
        // Focus camera towards this hotel
        const h = m.userData.hotel;
        setCoordinatesFocus(parseFloat(h.latitude), parseFloat(h.longitude), true, 8.8);
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

  function onMouseMove(event) {
    const rect = renderer.domElement.getBoundingClientRect();
    mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);

    // Collect clickable meshes
    const clickableObjects = [];
    hotelMarkers.forEach((m) => {
      if (m.userData.headMesh) clickableObjects.push(m.userData.headMesh);
    });

    const intersects = raycaster.intersectObjects(clickableObjects);

    if (intersects.length > 0) {
      const hit = intersects[0];
      const hotel = hit.object.userData.hotel;
      if (hotel) {
        renderer.domElement.style.cursor = 'pointer';
        showTooltip(event.clientX, event.clientY, hotel);
        return;
      }
    }

    renderer.domElement.style.cursor = 'grab';
    hideTooltip();
  }

  function onMouseClick(event) {
    const rect = renderer.domElement.getBoundingClientRect();
    mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);

    const clickableObjects = [];
    hotelMarkers.forEach((m) => {
      if (m.userData.headMesh) clickableObjects.push(m.userData.headMesh);
    });

    const intersects = raycaster.intersectObjects(clickableObjects);

    if (intersects.length > 0) {
      const hit = intersects[0];
      const hotel = hit.object.userData.hotel;
      if (hotel) {
        console.log(`[EarthGlobe] Hotel marker clicked: ${hotel.hotel_name} (ID: ${hotel.hotel_id})`);
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
            data.zoom || 9.2
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
        setCoordinatesFocus(17.385, 78.486, true, 13.0);
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
    }
    // 3. Auto-rotation when idle
    else if (isAutoRotating && Date.now() - lastUserInteraction > 2500) {
      if (earthGroup) {
        earthGroup.rotation.y += 0.0016;
      }
    }

    // 4. Animate pulsing rings on hotel markers
    hotelMarkers.forEach((m) => {
      if (m.userData.ringMesh) {
        m.userData.pulseVal = (m.userData.pulseVal || 0) + 0.04;
        const scale = 1.0 + Math.sin(m.userData.pulseVal) * 0.35;
        m.userData.ringMesh.scale.set(scale, scale, scale);
        m.userData.ringMesh.material.opacity = 0.8 - (scale - 1.0) * 0.6;
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
