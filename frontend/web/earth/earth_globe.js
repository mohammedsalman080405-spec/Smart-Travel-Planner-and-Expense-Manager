// Realistic 3D Earth Globe using Three.js WebGL & NASA Blue Marble Texture
// Communicates with Flutter Web via PostMessage & same-origin bridge

(function () {
  'use strict';

  let scene, camera, renderer, controls;
  let earthMesh, cloudsMesh, atmosphereMesh, nightLightsMesh, nightLightsMaterial, sunLight;
  let earthGroup;
  let starsMesh;
  const hotelMarkers = [];
  const flightPaths = [];
  const hotelRoutes = [];
  let cityCenterMarker = null;
  let cityRoutePlane = null;
  let cityRouteCurve = null;
  let cityCoordinates = null;
  let hasCityHotels = false;
  let hasCitySearch = false;
  let mapTransitionSent = false;
  let globalResetSent = false;
  let focusedLatitude = 20.0;
  let focusedLongitude = 20.0;
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
    sunLight = new THREE.DirectionalLight(0xffffff, 1.45);
    // Keep the initial India-facing hemisphere near twilight so the city-light layer reads clearly.
    sunLight.position.set(-22, 10, -14);
    scene.add(sunLight);

    const ambientLight = new THREE.AmbientLight(0x18243c, 0.4);
    scene.add(ambientLight);

    // 6. Deep Space Starfield with white & subtle electric-blue particles
    createStarfield();
    createGlobalFlightPaths();

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

  function createPlaneTexture() {
    const canvas = document.createElement('canvas');
    canvas.width = 128;
    canvas.height = 128;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#5beaff';
    ctx.shadowColor = '#00d9ff';
    ctx.shadowBlur = 18;
    ctx.beginPath();
    ctx.moveTo(64, 7);
    ctx.lineTo(74, 49);
    ctx.lineTo(119, 70);
    ctx.lineTo(119, 80);
    ctx.lineTo(75, 68);
    ctx.lineTo(75, 105);
    ctx.lineTo(89, 116);
    ctx.lineTo(89, 122);
    ctx.lineTo(64, 114);
    ctx.lineTo(39, 122);
    ctx.lineTo(39, 116);
    ctx.lineTo(53, 105);
    ctx.lineTo(53, 68);
    ctx.lineTo(9, 80);
    ctx.lineTo(9, 70);
    ctx.lineTo(54, 49);
    ctx.closePath();
    ctx.fill();
    const texture = new THREE.CanvasTexture(canvas);
    texture.needsUpdate = true;
    return texture;
  }

  function createGlobalFlightPaths() {
    const planeTexture = createPlaneTexture();
    const routes = [
      [[40.7128, -74.0060], [51.5072, -0.1276]],
      [[51.5072, -0.1276], [25.2048, 55.2708]],
      [[25.2048, 55.2708], [1.3521, 103.8198]],
      [[1.3521, 103.8198], [35.6762, 139.6503]],
      [[48.8566, 2.3522], [28.6139, 77.2090]]
    ];

    routes.forEach((route, index) => {
      const start = latLngToVector3(route[0][0], route[0][1], GLOBE_RADIUS + 0.045);
      const end = latLngToVector3(route[1][0], route[1][1], GLOBE_RADIUS + 0.045);
      const control = start.clone().add(end).normalize().multiplyScalar(GLOBE_RADIUS + 0.78);
      const curve = new THREE.QuadraticBezierCurve3(start, control, end);
      const geometry = new THREE.BufferGeometry().setFromPoints(curve.getPoints(96));
      const line = new THREE.Line(geometry, new THREE.LineBasicMaterial({
        color: 0x00cfff,
        transparent: true,
        opacity: 0.34,
        depthWrite: false
      }));
      line.renderOrder = 2;
      earthGroup.add(line);

      const material = new THREE.SpriteMaterial({
        map: planeTexture,
        transparent: true,
        opacity: 0.98,
        depthTest: true,
        depthWrite: false
      });
      const plane = new THREE.Sprite(material);
      plane.scale.set(0.42, 0.42, 1);
      plane.renderOrder = 3;
      earthGroup.add(plane);
      flightPaths.push({ curve, plane, speed: 0.018 + index * 0.001, offset: index / routes.length });
    });
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

    // Overlay city lights only on the unlit side of the globe.
    nightLightsMaterial = new THREE.ShaderMaterial({
      uniforms: {
        nightMap: { value: nightTexture },
        sunDirection: { value: sunLight.position.clone().normalize() }
      },
      vertexShader: `
        varying vec2 vUv;
        varying vec3 vNormal;
        void main() {
          vUv = uv;
          vNormal = normalize(normal);
          gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
      `,
      fragmentShader: `
        uniform sampler2D nightMap;
        uniform vec3 sunDirection;
        varying vec2 vUv;
        varying vec3 vNormal;
        void main() {
          vec4 lights = texture2D(nightMap, vUv);
          float nightSide = 1.0 - smoothstep(-0.12, 0.12, dot(normalize(vNormal), normalize(sunDirection)));
          float brightness = max(max(lights.r, lights.g), lights.b);
          gl_FragColor = vec4(lights.rgb * vec3(1.0, 0.58, 0.24) * 2.8, brightness * nightSide * 1.2);
        }
      `,
      blending: THREE.AdditiveBlending,
      transparent: true,
      depthWrite: false
    });
    nightLightsMesh = new THREE.Mesh(
      new THREE.SphereGeometry(GLOBE_RADIUS + 0.012, 64, 64),
      nightLightsMaterial
    );
    nightLightsMesh.renderOrder = 1;
    earthGroup.add(nightLightsMesh);

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
    focusedLatitude = lat;
    focusedLongitude = lng;

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

  // Keep every marker at the hotel's actual geographic coordinates. Labels are
  // callouts tethered to those locations, so nearby hotels remain individually legible.
  function calculateGeographicPlacements(hotels) {
    return (hotels || []).map(hotel => ({
      hotel,
      lat: Number(hotel.latitude),
      lng: Number(hotel.longitude)
    })).filter(p => Number.isFinite(p.lat) && Number.isFinite(p.lng) &&
      Math.abs(p.lat) <= 90 && Math.abs(p.lng) <= 180 && (p.lat !== 0 || p.lng !== 0));
  }

  function roundedRect(ctx, x, y, width, height, radius) {
    ctx.beginPath();
    ctx.roundRect(x, y, width, height, radius);
  }

  function makeHotelCardTexture(hotel) {
    const canvas = document.createElement('canvas');
    canvas.width = 640;
    canvas.height = 192;
    const ctx = canvas.getContext('2d');
    let texture;
    const draw = (photo = null) => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.shadowColor = 'rgba(0,217,255,.8)';
      ctx.shadowBlur = 18;
      roundedRect(ctx, 8, 8, 624, 176, 26);
      ctx.fillStyle = 'rgba(4,12,24,.97)';
      ctx.fill();
      ctx.shadowBlur = 0;
      ctx.lineWidth = 4;
      ctx.strokeStyle = '#00d9ff';
      ctx.stroke();

      ctx.save();
      ctx.beginPath();
      ctx.arc(101, 96, 69, 0, Math.PI * 2);
      ctx.clip();
      if (photo) {
        const ratio = Math.max(138 / photo.width, 138 / photo.height);
        const w = photo.width * ratio, h = photo.height * ratio;
        ctx.drawImage(photo, 101 - w / 2, 96 - h / 2, w, h);
      } else {
        ctx.fillStyle = '#101827';
        ctx.fillRect(32, 27, 138, 138);
        ctx.fillStyle = '#00d9ff';
        ctx.font = '76px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('⌂', 101, 96);
      }
      ctx.restore();
      ctx.lineWidth = 6;
      ctx.strokeStyle = '#00d9ff';
      ctx.beginPath();
      ctx.arc(101, 96, 69, 0, Math.PI * 2);
      ctx.stroke();

      const name = String(hotel.hotel_name || 'Hotel');
      ctx.textAlign = 'left';
      ctx.textBaseline = 'alphabetic';
      ctx.fillStyle = '#fff';
      ctx.font = 'bold 31px Arial, sans-serif';
      ctx.fillText(name.length > 27 ? `${name.slice(0, 25)}…` : name, 190, 69, 420);
      ctx.fillStyle = '#ffc52f';
      ctx.font = '26px Arial, sans-serif';
      const rating = Number(hotel.star_rating);
      const ratingText = Number.isFinite(rating) && rating > 0 ? `★ ${rating.toFixed(1)}` : 'Hotel';
      ctx.fillText(`${ratingText}  ·  ${Number(hotel.review_count || 0).toLocaleString()} reviews`, 190, 111, 420);
      const amount = Number(hotel.starting_price);
      let price = 'Price unavailable';
      if (Number.isFinite(amount) && amount > 0) {
        try {
          price = `${new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(amount)} / night`;
        } catch (_) { price = `${amount.toFixed(0)} / night`; }
      }
      ctx.fillStyle = '#00d9ff';
      ctx.font = 'bold 29px Arial, sans-serif';
      ctx.fillText(price, 190, 153, 420);
      if (texture) texture.needsUpdate = true;
    };
    draw();
    texture = new THREE.CanvasTexture(canvas);

    const photoUrl = hotel.exterior_image_url;
    if (photoUrl && /^https?:\/\//i.test(photoUrl)) {
      const image = new Image();
      image.crossOrigin = 'anonymous';
      image.onload = () => draw(image);
      image.onerror = () => draw();
      image.src = photoUrl;
    }
    return texture;
  }

  function renderHotelRoutes(placements) {
    hotelRoutes.forEach(route => {
      earthGroup.remove(route);
      route.geometry.dispose();
      route.material.dispose();
    });
    hotelRoutes.length = 0;
    if (cityCenterMarker) {
      earthGroup.remove(cityCenterMarker);
      cityCenterMarker.material.dispose();
      cityCenterMarker = null;
    }
    if (cityRoutePlane) {
      earthGroup.remove(cityRoutePlane);
      cityRoutePlane.material.dispose();
      cityRoutePlane = null;
      cityRouteCurve = null;
    }
    if (!cityCoordinates || !placements.length) return;

    const center = latLngToVector3(cityCoordinates.latitude, cityCoordinates.longitude, GLOBE_RADIUS + 0.035);
    cityCenterMarker = new THREE.Sprite(new THREE.SpriteMaterial({
      map: getCyanDotTexture(), color: 0xffffff, transparent: true,
      depthTest: true, depthWrite: false, blending: THREE.AdditiveBlending
    }));
    cityCenterMarker.position.copy(center);
    cityCenterMarker.scale.set(0.34, 0.34, 1);
    cityCenterMarker.renderOrder = 4;
    earthGroup.add(cityCenterMarker);

    const planeTexture = createPlaneTexture();
    placements.forEach((placement, index) => {
      const start = center.clone();
      const end = latLngToVector3(placement.lat, placement.lng, GLOBE_RADIUS + 0.04);
      const midpoint = start.clone().add(end).normalize().multiplyScalar(GLOBE_RADIUS + 0.10);
      const curve = new THREE.QuadraticBezierCurve3(start, midpoint, end);
      const geometry = new THREE.BufferGeometry().setFromPoints(curve.getPoints(48));
      const material = new THREE.LineDashedMaterial({
        color: 0x00d9ff, dashSize: 0.055, gapSize: 0.045,
        transparent: true, opacity: 0.92, depthWrite: false
      });
      const line = new THREE.Line(geometry, material);
      line.computeLineDistances();
      line.renderOrder = 2;
      earthGroup.add(line);
      hotelRoutes.push(line);
      if (index === 0) cityRouteCurve = curve;
    });
    if (cityRouteCurve) {
      cityRoutePlane = new THREE.Sprite(new THREE.SpriteMaterial({
        map: planeTexture, transparent: true, depthTest: true, depthWrite: false
      }));
      cityRoutePlane.scale.set(0.20, 0.20, 1);
      cityRoutePlane.renderOrder = 4;
      earthGroup.add(cityRoutePlane);
    }
  }

  // Place a real-coordinate pin on the sphere and keep its readable card tethered
  // to the pin with a leader line. The card remains a child of the geographic marker.
  function renderHotelMarkers(hotelsList) {
    console.log(`[EarthGlobe] Rendering ${hotelsList ? hotelsList.length : 0} hotel cards on globe...`);
    clearHotelMarkers();

    if (!hotelsList || hotelsList.length === 0) {
      hasCityHotels = false;
      console.log('[EarthGlobe] Zero hotels provided. Globe markers cleared.');
      return;
    }

    const placements = calculateGeographicPlacements(hotelsList);
    hasCityHotels = placements.length > 0;
    renderHotelRoutes(placements);

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
      const baseScale = 0.14;
      dotSprite.scale.set(baseScale, baseScale, 1.0);
      markerGroup.add(dotSprite);

      // Spread labels around each city's pin cluster while leaving the pin on its
      // exact coordinate. Five-card rings keep dense hotel areas readable.
      const ringIndex = Math.floor(idx / 5);
      const slot = idx % 5;
      const angle = (slot / 5) * Math.PI * 2 + ringIndex * 0.34;
      const ringRadius = 1.25 + ringIndex * 1.0;
      const cardOffset = new THREE.Vector3(Math.cos(angle) * ringRadius, 0.20, Math.sin(angle) * ringRadius);
      const leader = new THREE.Line(
        new THREE.BufferGeometry().setFromPoints([
          new THREE.Vector3(0, 0.02, 0),
          new THREE.Vector3(cardOffset.x * 0.82, cardOffset.y, cardOffset.z * 0.82)
        ]),
        new THREE.LineBasicMaterial({ color: 0x00d9ff, transparent: true, opacity: 0.8, depthTest: true })
      );
      leader.renderOrder = 3;
      markerGroup.add(leader);

      const cardTexture = makeHotelCardTexture(hotel);
      const cardSprite = new THREE.Sprite(new THREE.SpriteMaterial({
        map: cardTexture,
        transparent: true,
        depthTest: true,
        depthWrite: false
      }));
      cardSprite.position.copy(cardOffset);
      cardSprite.scale.set(1.72, 0.516, 1);
      cardSprite.renderOrder = 5;
      markerGroup.add(cardSprite);

      // Hit proxies make both the true pin and the card interactive.
      const hitGeometry = new THREE.SphereGeometry(0.11, 10, 10);
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
        cardSprite: cardSprite,
        leader: leader,
        cardTexture: cardTexture,
        pulsePhase: (idx * 0.78) % (Math.PI * 2),
        baseScale: baseScale
      };
      hitMesh.userData = markerGroup.userData;
      cardSprite.userData = markerGroup.userData;

      earthGroup.add(markerGroup);
      hotelMarkers.push(markerGroup);
    });

    console.log(`[EarthGlobe] Successfully rendered ${hotelMarkers.length} distinct geographic hotel markers.`);
  }

  function clearHotelMarkers() {
    hotelMarkers.forEach((marker) => {
      earthGroup.remove(marker);
      marker.userData.cardTexture?.dispose();
      marker.userData.hitMesh?.geometry.dispose();
      marker.userData.hitMesh?.material.dispose();
      marker.userData.leader?.geometry.dispose();
      marker.userData.leader?.material.dispose();
      marker.userData.dotSprite?.material.dispose();
      marker.userData.cardSprite?.material.dispose();
    });
    hotelMarkers.length = 0;
    hotelRoutes.forEach(route => {
      earthGroup.remove(route);
      route.geometry.dispose();
      route.material.dispose();
    });
    hotelRoutes.length = 0;
    if (cityCenterMarker) {
      earthGroup.remove(cityCenterMarker);
      cityCenterMarker.material.dispose();
      cityCenterMarker = null;
    }
    if (cityRoutePlane) {
      earthGroup.remove(cityRoutePlane);
      cityRoutePlane.material.map?.dispose();
      cityRoutePlane.material.dispose();
      cityRoutePlane = null;
    }
    cityRouteCurve = null;
    hasCityHotels = false;
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
        clickableObjects.push(m.userData.cardSprite);
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
        clickableObjects.push(m.userData.cardSprite);
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
    const amount = Number(hotel.starting_price);
    let price = 'Price unavailable';
    if (Number.isFinite(amount) && amount > 0) {
      try {
        price = new Intl.NumberFormat(undefined, {
          style: 'currency',
          currency: 'INR',
          maximumFractionDigits: 0
        }).format(amount);
      } catch (_) { price = amount.toFixed(0); }
      price += ' / night';
    }
    const rating = Number(hotel.star_rating);
    tooltipSub.textContent = `${price} • ${Number.isFinite(rating) && rating > 0 ? `★ ${rating.toFixed(1)}` : 'Rating unavailable'}`;
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
          if (Number.isFinite(Number(data.destination_latitude)) && Number.isFinite(Number(data.destination_longitude))) {
            cityCoordinates = {
              latitude: Number(data.destination_latitude),
              longitude: Number(data.destination_longitude)
            };
          } else {
            cityCoordinates = { latitude: focusedLatitude, longitude: focusedLongitude };
          }
          mapTransitionSent = false;
          globalResetSent = false;
          hasCitySearch = true;
          renderHotelMarkers(data.hotels);
        }
        break;

      case 'SELECT_HOTEL':
        if (data.hotelId !== undefined) {
          selectHotelMarker(data.hotelId);
        }
        break;

      case 'CLEAR_HOTELS':
        hasCitySearch = false;
        cityCoordinates = null;
        mapTransitionSent = false;
        globalResetSent = false;
        clearHotelMarkers();
        break;

      case 'TOGGLE_AUTO_ROTATE':
        isAutoRotating = !!data.enabled;
        break;

      case 'RESET_VIEW':
        cityCoordinates = null;
        hasCitySearch = false;
        mapTransitionSent = false;
        globalResetSent = false;
        clearHotelMarkers();
        setCoordinatesFocus(20.0, 20.0, true, 15.8);
        isAutoRotating = true;
        break;

      case 'ZOOM_STEP': {
        const step = data.direction === 'out' ? 2.2 : -2.2;
        targetCameraDistance = THREE.MathUtils.clamp(camera.position.length() + step, 6.8, 24);
        isAnimatingTarget = true;
        isAutoRotating = false;
        lastUserInteraction = Date.now();
        break;
      }

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

    const flightTime = Date.now() * 0.001;
    if (nightLightsMaterial && sunLight && earthGroup) {
      nightLightsMaterial.uniforms.sunDirection.value
        .copy(sunLight.position)
        .normalize()
        .applyQuaternion(earthGroup.quaternion.clone().invert());
    }
    flightPaths.forEach((path) => {
      const progress = (flightTime * path.speed + path.offset) % 1;
      const point = path.curve.getPointAt(progress);
      const next = path.curve.getPointAt((progress + 0.003) % 1);
      const pointScreen = point.clone().project(camera);
      const nextScreen = next.clone().project(camera);
      path.plane.position.copy(point);
      path.plane.material.rotation = Math.atan2(nextScreen.y - pointScreen.y, nextScreen.x - pointScreen.x);
    });

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
      const currentDistance = camera.position.length();
      const distDiff = targetCameraDistance - currentDistance;
      if (Math.abs(distDiff) > 0.05) {
        camera.position.setLength(currentDistance + distDiff * 0.08);
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
    if (cityRoutePlane && cityRouteCurve) {
      cityRoutePlane.position.copy(cityRouteCurve.getPointAt((flightTime * 0.12) % 1));
    }
    const cameraDistance = camera.position.distanceTo(controls.target);
    if (hasCitySearch && cameraDistance <= 7.45 && !mapTransitionSent) {
      mapTransitionSent = true;
      notifyFlutter({ type: 'OPEN_CITY_MAP' });
    }
    if (hasCitySearch && cameraDistance >= 20.8 && !globalResetSent) {
      globalResetSent = true;
      notifyFlutter({ type: 'RETURN_TO_GLOBAL' });
    }
    renderer.render(scene, camera);
  }

  // Initialize once DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
