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
  let targetCameraDistance = 15.8;

  const container = document.getElementById('globe-container');
  const tooltip = document.getElementById('hotel-tooltip');
  const tooltipTitle = document.getElementById('tooltip-title');
  const tooltipSub = document.getElementById('tooltip-sub');
  const loadingOverlay = document.getElementById('loading-overlay');

  // Dynamic responsive view offset calculation:
  // Shifts the projected 3D Earth rightwards and downwards
  // Exactly matching the latest reference image (Earth center at x=565, y=385 on a 1024x656 screen)
  function updateCameraViewOffset() {
    if (!container || !camera) return;
    const w = container.clientWidth;
    const h = container.clientHeight;
    const isDesktop = w >= 780;

    if (isDesktop) {
      // In 1024x656 reference image:
      // Earth center is shifted +53px right from screen center 512px
      // Earth center is shifted +57px down from screen center 328px
      const deltaX = Math.round(53.0 * (w / 1024.0));
      const deltaY = Math.round(57.0 * (h / 656.0));
      camera.setViewOffset(w, h, -deltaX, -deltaY, w, h);
    } else {
      const deltaY = Math.round(24.0 * (h / 656.0));
      camera.setViewOffset(w, h, 0, -deltaY, w, h);
    }
    camera.updateProjectionMatrix();
  }

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
    updateCameraViewOffset();
    camera.position.set(0, 0, 15.8);

    // 2. Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.2;
    container.appendChild(renderer.domElement);
    renderer.domElement.id = 'globe-canvas';

    // 3. OrbitControls centered around the Earth
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.rotateSpeed = 0.6;
    controls.zoomSpeed = 0.8;
    controls.minDistance = 6.8;
    controls.maxDistance = 24.0;
    controls.enablePan = false;
    controls.target.set(0, 0, 0);

    controls.addEventListener('start', onInteractionStart);
    controls.addEventListener('end', onInteractionEnd);

    // 4. Earth Group (holds Earth, clouds, and markers)
    earthGroup = new THREE.Group();
    earthGroup.position.set(0, 0, 0);
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
    atmosphereMesh.position.set(0, 0, 0);
    scene.add(atmosphereMesh);

    // Set initial camera view showing South Asia / India facing forward matching the reference image
    setCoordinatesFocus(17.385044, 78.486671, false, 15.8);
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
    console.log(`[EarthGlobe] Focusing coordinates: lat=${lat}, lng=${lng}, animate=${animate}, zoom=${zoomDistance}`);
    const targets = getTargetRotation(lat, lng);
    targetRotationY = targets.rotY;
    targetRotationX = targets.rotX;
    targetCameraDistance = zoomDistance;

    if (!animate) {
      earthGroup.rotation.y = targetRotationY;
      earthGroup.rotation.x = targetRotationX;
      camera.position.set(0, 0, targetCameraDistance);
      controls.target.set(0, 0, 0);
    } else {
      isAnimatingTarget = true;
      isAutoRotating = false;
      lastUserInteraction = Date.now();
    }
  }

  // Cached procedural glowing dot textures for optimal WebGL performance
  // Small, elegant cyan circular marker with a crisp white centre and subtle cyan glow
  let cyanDotTexture = null;
  let goldDotTexture = null;

  function getCyanDotTexture() {
    if (cyanDotTexture) return cyanDotTexture;
    const canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    const ctx = canvas.getContext('2d');
    const cx = 64, cy = 64;

    // 1. Soft, subtle outer cyan aura (fades smoothly to transparent)
    const glow = ctx.createRadialGradient(cx, cy, 20, cx, cy, 62);
    glow.addColorStop(0.0, 'rgba(0, 240, 255, 0.50)');
    glow.addColorStop(0.35, 'rgba(0, 215, 255, 0.20)');
    glow.addColorStop(1.0, 'rgba(0, 180, 255, 0.0)');
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(cx, cy, 62, 0, Math.PI * 2);
    ctx.fill();

    // 2. Intense, crisp electric-cyan ring
    const ring = ctx.createRadialGradient(cx, cy, 11, cx, cy, 25);
    ring.addColorStop(0.0, 'rgba(0, 248, 255, 1.0)');
    ring.addColorStop(0.7, 'rgba(0, 220, 255, 0.95)');
    ring.addColorStop(1.0, 'rgba(0, 185, 255, 0.6)');
    ctx.fillStyle = ring;
    ctx.beginPath();
    ctx.arc(cx, cy, 25, 0, Math.PI * 2);
    ctx.fill();

    // 3. Crisp solid pure white circular core / centre
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(cx, cy, 12, 0, Math.PI * 2);
    ctx.fill();

    cyanDotTexture = new THREE.CanvasTexture(canvas);
    return cyanDotTexture;
  }

  function getGoldDotTexture() {
    if (goldDotTexture) return goldDotTexture;
    const canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    const ctx = canvas.getContext('2d');
    const cx = 64, cy = 64;

    const glow = ctx.createRadialGradient(cx, cy, 20, cx, cy, 62);
    glow.addColorStop(0.0, 'rgba(255, 215, 0, 0.55)');
    glow.addColorStop(0.35, 'rgba(245, 158, 11, 0.22)');
    glow.addColorStop(1.0, 'rgba(217, 119, 6, 0.0)');
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(cx, cy, 62, 0, Math.PI * 2);
    ctx.fill();

    const ring = ctx.createRadialGradient(cx, cy, 11, cx, cy, 25);
    ring.addColorStop(0.0, 'rgba(255, 225, 60, 1.0)');
    ring.addColorStop(0.7, 'rgba(250, 180, 20, 0.95)');
    ring.addColorStop(1.0, 'rgba(230, 140, 10, 0.6)');
    ctx.fillStyle = ring;
    ctx.beginPath();
    ctx.arc(cx, cy, 25, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(cx, cy, 12, 0, Math.PI * 2);
    ctx.fill();

    goldDotTexture = new THREE.CanvasTexture(canvas);
    return goldDotTexture;
  }

  // Calculate geographically accurate, distinct placements for all returned hotels
  // Ensures every hotel has its own separate dot at its true geographic direction from destination centre
  // with sufficient visual clearance so dots never overlap into a merged blob
  function calculateGeographicPlacements(hotels) {
    if (!hotels || hotels.length === 0) return [];
    if (hotels.length === 1) {
      return [{
        hotel: hotels[0],
        lat: parseFloat(hotels[0].latitude),
        lng: parseFloat(hotels[0].longitude)
      }];
    }

    let sumLat = 0, sumLng = 0, validCount = 0;
    hotels.forEach(h => {
      const lat = parseFloat(h.latitude);
      const lng = parseFloat(h.longitude);
      if (!isNaN(lat) && !isNaN(lng)) {
        sumLat += lat;
        sumLng += lng;
        validCount++;
      }
    });
    if (validCount === 0) return [];

    const cLat = sumLat / validCount;
    const cLng = sumLng / validCount;
    const cosLat = Math.cos(cLat * Math.PI / 180) || 1.0;

    const pts = [];
    let maxDist = 0.0001;

    hotels.forEach((h, idx) => {
      const lat = parseFloat(h.latitude);
      const lng = parseFloat(h.longitude);
      if (isNaN(lat) || isNaN(lng)) return;

      const dLat = lat - cLat;
      const dLng = (lng - cLng) * cosLat;
      const dist = Math.hypot(dLat, dLng);
      if (dist > maxDist) maxDist = dist;

      pts.push({
        hotel: h,
        origLat: lat,
        origLng: lng,
        dLat: dLat,
        dLng: dLng,
        x: dLng,
        y: dLat,
        idx: idx
      });
    });

    // Target visual spread on the globe and minimum pairwise clearance
    // Preserves each hotel's compass bearing and relative location around the destination
    const targetSpread = 2.6; // degrees on Earth surface
    const minSeparation = 0.65; // degrees minimum separation between distinct dots

    if (maxDist < targetSpread * 0.5) {
      const scale = (targetSpread * 0.5) / maxDist;
      pts.forEach(p => {
        p.x *= scale;
        p.y *= scale;
      });
    }

    // Iterative repulsion so no two dots overlap into a single blob
    for (let iter = 0; iter < 35; iter++) {
      for (let i = 0; i < pts.length; i++) {
        for (let j = i + 1; j < pts.length; j++) {
          let dx = pts[i].x - pts[j].x;
          let dy = pts[i].y - pts[j].y;
          let d = Math.hypot(dx, dy);
          if (d < minSeparation) {
            const overlap = minSeparation - d;
            if (d < 1e-5) {
              const ang = (pts[i].idx * 1.618033) * Math.PI * 2;
              dx = Math.cos(ang) * 0.02;
              dy = Math.sin(ang) * 0.02;
              d = Math.hypot(dx, dy);
            }
            const pushX = (dx / d) * (overlap * 0.5);
            const pushY = (dy / d) * (overlap * 0.5);
            pts[i].x += pushX;
            pts[i].y += pushY;
            pts[j].x -= pushX;
            pts[j].y -= pushY;
          }
        }
      }
    }

    return pts.map(p => {
      const lat = cLat + p.y;
      const lng = cLng + (p.x / cosLat);
      return {
        hotel: p.hotel,
        lat: lat,
        lng: lng
      };
    });
  }

  // Render individual hotel markers: exactly 1 dot per hotel, white center + cyan glow
  function renderHotelMarkers(hotelsList) {
    console.log(`[EarthGlobe] Rendering ${hotelsList ? hotelsList.length : 0} individual hotel dots on globe...`);
    clearHotelMarkers();

    if (!hotelsList || hotelsList.length === 0) {
      console.log('[EarthGlobe] Zero hotels provided. Globe markers cleared.');
      return;
    }

    const placements = calculateGeographicPlacements(hotelsList);

    placements.forEach((placement, idx) => {
      const hotel = placement.hotel;
      const surfaceRadius = GLOBE_RADIUS + 0.025;
      const pos = latLngToVector3(placement.lat, placement.lng, surfaceRadius);

      const markerGroup = new THREE.Group();
      markerGroup.position.copy(pos);

      // Orient marker container along the surface normal
      const normal = pos.clone().normalize();
      markerGroup.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), normal);

      // 1. Small elegant cyan circular marker with a crisp white centre and subtle cyan glow
      const spriteMaterial = new THREE.SpriteMaterial({
        map: getCyanDotTexture(),
        color: 0xffffff,
        transparent: true,
        opacity: 0.96,
        blending: THREE.NormalBlending,
        depthTest: true,
        depthWrite: false
      });
      const dotSprite = new THREE.Sprite(spriteMaterial);
      const baseScale = 0.075;
      dotSprite.scale.set(baseScale, baseScale, 1.0);
      markerGroup.add(dotSprite);

      // 2. Invisible Hit Proxy for Smooth, Reliable Mouse Clicking
      const hitGeometry = new THREE.SphereGeometry(0.065, 8, 8);
      const hitMaterial = new THREE.MeshBasicMaterial({ visible: false });
      const hitMesh = new THREE.Mesh(hitGeometry, hitMaterial);
      markerGroup.add(hitMesh);

      // Store metadata
      markerGroup.userData = {
        hotel: hotel,
        hotelId: hotel.hotel_id,
        isHotelMarker: true,
        dotSprite: dotSprite,
        hitMesh: hitMesh,
        pulsePhase: (idx * 0.78) % (Math.PI * 2),
        baseScale: baseScale
      };
      hitMesh.userData = markerGroup.userData;

      earthGroup.add(markerGroup);
      hotelMarkers.push(markerGroup);
    });

    console.log(`[EarthGlobe] Successfully rendered ${hotelMarkers.length} distinct individual hotel markers.`);
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
      if (m.userData.dotSprite) {
        m.userData.dotSprite.material.map = isSelected ? getGoldDotTexture() : getCyanDotTexture();
        const selScale = isSelected ? 0.095 : m.userData.baseScale;
        m.userData.dotSprite.scale.set(selScale, selScale, 1.0);
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
            hoveredMarker.userData.dotSprite.scale.set(
              hoveredMarker.userData.baseScale,
              hoveredMarker.userData.baseScale,
              1.0
            );
          }
          hoveredMarker = m;
          const hovScale = m.userData.hotelId === selectedMarkerId ? 0.105 : 0.092;
          m.userData.dotSprite.scale.set(hovScale, hovScale, 1.0);
        }
        return;
      }
    }

    if (hoveredMarker) {
      if (hoveredMarker.userData.hotelId !== selectedMarkerId) {
        hoveredMarker.userData.dotSprite.scale.set(
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
        setCoordinatesFocus(17.385044, 78.486671, true, 15.8);
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
    updateCameraViewOffset();
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

      controls.target.set(0, 0, 0);
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
        if (m.userData.dotSprite && m !== hoveredMarker && m.userData.hotelId !== selectedMarkerId) {
          const pulse = 1.0 + 0.05 * Math.sin(timeNow + (m.userData.pulsePhase || 0));
          const s = m.userData.baseScale * pulse;
          m.userData.dotSprite.scale.set(s, s, 1.0);
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
