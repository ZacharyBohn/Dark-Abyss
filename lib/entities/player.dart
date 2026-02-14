import 'dart:math';
import 'dart:ui';

import '../data/constants.dart';
import '../game/input_handler.dart';
import '../utils/math_utils.dart';
import 'entity.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  dashing,
  wallSliding,
  attacking,
  hit,
}

class Afterimage {
  Vector2 position;
  double opacity;
  bool facingRight;

  Afterimage({
    required this.position,
    required this.opacity,
    required this.facingRight,
  });
}

class Player extends Entity {
  PlayerState state = PlayerState.idle;

  // Stats
  double maxHP = playerBaseHP;
  double currentHP = playerBaseHP;
  double atk = playerBaseATK;
  double def = playerBaseDEF;
  double spd = playerBaseSPD;
  double maxEnergy = playerBaseEnergy;
  double currentEnergy = playerBaseEnergy;
  int level = 1;
  int xp = 0;

  // Movement state
  bool isGrounded = false;
  bool wasGrounded = false;
  bool isTouchingWallLeft = false;
  bool isTouchingWallRight = false;
  int jumpsRemaining = 1;
  int maxJumps = 1; // Becomes 2 when double jump unlocked

  // Dash state
  bool isDashing = false;
  bool canDash = true;
  double dashTimer = 0;
  double dashCooldownTimer = 0;
  Vector2 dashDirection = Vector2.zero();
  bool hasIFrames = false;

  // Afterimages for dash trail
  List<Afterimage> afterimages = [];
  double afterimageTimer = 0;
  static const double afterimageInterval = 0.02;

  // Wall slide/jump
  bool isWallSliding = false;
  int wallDirection = 0; // -1 left, 1 right, 0 none
  static const double wallSlideSpeed = 100.0;
  static const double wallJumpHorizontalForce = 350.0;

  // Drop-through platform
  double dropThroughTimer = 0;
  bool isDropping = false;
  static const double dropThroughHoldTime = 0.7;

  // Coyote time (allows jump shortly after leaving platform)
  double coyoteTimer = 0;
  static const double coyoteTime = 0.1;

  // Jump buffer (registers jump input slightly before landing)
  double jumpBufferTimer = 0;
  static const double jumpBufferTime = 0.1;

  // Attack state
  bool isAttacking = false;
  double attackTimer = 0;
  double attackCooldownTimer = 0;
  static const double attackDuration = 0.08; // Fast slash
  static const double attackCooldown = 0.08; // Quick recovery for combos
  double attackAngle = 0; // Direction of attack arc
  bool attackHitThisSwing = false; // Prevent multi-hit per swing

  // Combo system
  int comboCount = 0;
  double comboTimer = 0;
  static const double comboWindow = 0.5;
  int maxCombo = 3;

  // Upgrade-applied stats
  double attackMultiplier = 1.0;
  double lifeStealPercent = 0.0;
  double critChance = 0.0;
  double critMultiplier = 2.0;
  double energyRegenRate = 1.0;
  bool canAirDash = false;
  double dashCooldownMultiplier = 1.0;

  // Hit state
  bool isHit = false;
  double hitStunTimer = 0;
  double hitFlashTimer = 0;
  double iFrameTimer = 0;

  Player({required super.position})
      : super(
          width: playerWidth,
          height: playerHeight,
        );

  void handleInput(InputState input, double dt) {
    // Clear just-pressed flags at end of frame
    // (they're consumed by the actions below)

    // Drop-through mechanic - hold down while grounded
    if (input.down && isGrounded && !isDashing) {
      dropThroughTimer += dt;
      if (dropThroughTimer >= dropThroughHoldTime) {
        isDropping = true;
        dropThroughTimer = 0;
      }
    } else {
      dropThroughTimer = 0;
    }

    // Horizontal movement (unless dashing)
    if (!isDashing) {
      final moveDir = input.horizontalInput;
      if (moveDir != 0) {
        velocity.x = moveDir * playerSpeed * spd;
        facingRight = moveDir > 0;
      } else {
        // Apply friction
        velocity.x *= 0.8;
        if (velocity.x.abs() < 10) velocity.x = 0;
      }
    }

    // Jump buffer
    if (input.jumpPressed) {
      jumpBufferTimer = jumpBufferTime;
    }

    // Jump
    if (jumpBufferTimer > 0) {
      if (isGrounded || coyoteTimer > 0 || jumpsRemaining > 0) {
        _performJump();
        jumpBufferTimer = 0;
      } else if (isWallSliding) {
        _performWallJump();
        jumpBufferTimer = 0;
      }
    }

    // Dash (block air dash unless upgrade owned)
    if (input.dashPressed && canDash && !isDashing) {
      if (isGrounded || canAirDash) {
        _startDash(input);
      }
    }

    // Attack
    if (input.attackPressed && !isAttacking && attackCooldownTimer <= 0 && !isDashing) {
      _startAttack(input);
    }
  }

  void _startAttack(InputState input) {
    isAttacking = true;
    attackTimer = attackDuration;
    attackHitThisSwing = false;

    // Determine attack direction
    final moveDir = input.moveDirection;
    if (moveDir.length > 0.1) {
      // Attack in input direction
      attackAngle = moveDir.angle;
    } else {
      // Attack in facing direction
      attackAngle = facingRight ? 0 : pi;
    }

    // Combo logic
    if (comboTimer > 0 && comboCount < maxCombo) {
      comboCount++;
    } else {
      comboCount = 1;
    }
    comboTimer = comboWindow;

    state = PlayerState.attacking;

    // Quick forward lunge for impact
    velocity.x = (facingRight ? 1 : -1) * 350;
  }

  void _performJump() {
    velocity.y = jumpForce;
    isGrounded = false;
    coyoteTimer = 0;
    if (!wasGrounded) {
      jumpsRemaining--;
    }
    state = PlayerState.jumping;
  }

  void _performWallJump() {
    // Jump away from wall
    velocity.y = jumpForce * 0.9;
    velocity.x = -wallDirection * wallJumpHorizontalForce;
    facingRight = wallDirection < 0;
    isWallSliding = false;
    wallDirection = 0;
    state = PlayerState.jumping;
  }

  void _startDash(InputState input) {
    isDashing = true;
    canDash = false;
    dashTimer = dashDuration;
    hasIFrames = true;

    // Dash in input direction, or facing direction if no input
    final moveDir = input.moveDirection;
    if (moveDir.length > 0) {
      dashDirection = moveDir.normalized();
    } else {
      dashDirection = Vector2(facingRight ? 1 : -1, 0);
    }

    velocity = dashDirection * dashSpeed;
    state = PlayerState.dashing;

    // Add initial afterimage
    afterimages.add(Afterimage(
      position: position.copy(),
      opacity: 0.8,
      facingRight: facingRight,
    ));
  }

  @override
  void update(double dt) {
    wasGrounded = isGrounded;

    // Clear drop-through flag after leaving ground
    if (!isGrounded) {
      isDropping = false;
    }

    // Update timers
    if (jumpBufferTimer > 0) jumpBufferTimer -= dt;
    if (coyoteTimer > 0) coyoteTimer -= dt;
    if (comboTimer > 0) comboTimer -= dt;
    if (iFrameTimer > 0) iFrameTimer -= dt;
    if (hitFlashTimer > 0) hitFlashTimer -= dt;
    if (attackCooldownTimer > 0) attackCooldownTimer -= dt;

    // Hit stun
    if (hitStunTimer > 0) {
      hitStunTimer -= dt;
      if (hitStunTimer <= 0) {
        isHit = false;
      }
    }

    // Attack logic
    if (isAttacking) {
      attackTimer -= dt;
      if (attackTimer <= 0) {
        isAttacking = false;
        attackCooldownTimer = attackCooldown;
      }
    }

    // Combo timeout
    if (comboTimer <= 0) {
      comboCount = 0;
    }

    // Dash cooldown
    if (!canDash && !isDashing) {
      dashCooldownTimer -= dt;
      if (dashCooldownTimer <= 0) {
        canDash = true;
      }
    }

    // Dash logic
    if (isDashing) {
      dashTimer -= dt;

      // Add afterimages during dash
      afterimageTimer -= dt;
      if (afterimageTimer <= 0) {
        afterimages.add(Afterimage(
          position: position.copy(),
          opacity: 0.6,
          facingRight: facingRight,
        ));
        afterimageTimer = afterimageInterval;
      }

      if (dashTimer <= 0) {
        isDashing = false;
        hasIFrames = false;
        dashCooldownTimer = dashCooldown * dashCooldownMultiplier;
        // Reduce velocity after dash
        velocity = velocity * 0.3;
      }
    } else {
      // Apply gravity when not dashing
      if (!isGrounded) {
        if (isWallSliding) {
          // Slower fall when wall sliding
          velocity.y += gravity * dt * 0.3;
          if (velocity.y > wallSlideSpeed) {
            velocity.y = wallSlideSpeed;
          }
        } else {
          velocity.y += gravity * dt;
        }
      }
    }

    // Apply velocity
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // Update afterimages (fade out)
    for (var i = afterimages.length - 1; i >= 0; i--) {
      afterimages[i].opacity -= dt * 3;
      if (afterimages[i].opacity <= 0) {
        afterimages.removeAt(i);
      }
    }

    // Limit afterimages
    while (afterimages.length > maxAfterimages) {
      afterimages.removeAt(0);
    }

    // Update state
    _updateState();
  }

  void _updateState() {
    if (isHit) {
      state = PlayerState.hit;
    } else if (isAttacking) {
      state = PlayerState.attacking;
    } else if (isDashing) {
      state = PlayerState.dashing;
    } else if (isWallSliding) {
      state = PlayerState.wallSliding;
    } else if (!isGrounded) {
      state = velocity.y < 0 ? PlayerState.jumping : PlayerState.falling;
    } else if (velocity.x.abs() > 10) {
      state = PlayerState.running;
    } else {
      state = PlayerState.idle;
    }
  }

  void onLand() {
    isGrounded = true;
    jumpsRemaining = maxJumps;
    velocity.y = 0;

    // Reset dash when landing
    if (!isDashing) {
      canDash = true;
    }
  }

  void onLeaveGround() {
    isGrounded = false;
    if (wasGrounded) {
      coyoteTimer = coyoteTime;
    }
  }

  void onTouchWall(int direction) {
    wallDirection = direction;
    if (!isGrounded && velocity.y > 0) {
      isWallSliding = true;
      // Reset jumps when touching wall
      jumpsRemaining = maxJumps;
    }
  }

  void onLeaveWall() {
    isWallSliding = false;
    wallDirection = 0;
  }

  Rect get feetRect => Rect.fromLTWH(
        position.x - width / 2 + 4,
        position.y + height / 2 - 4,
        width - 8,
        8,
      );

  Rect get leftRect => Rect.fromLTWH(
        position.x - width / 2 - 2,
        position.y - height / 2 + 8,
        4,
        height - 16,
      );

  Rect get rightRect => Rect.fromLTWH(
        position.x + width / 2 - 2,
        position.y - height / 2 + 8,
        4,
        height - 16,
      );

  /// Get the attack hitbox based on current attack angle
  /// Returns null if not attacking
  Rect? get attackHitbox {
    if (!isAttacking) return null;

    // Attack arc extends in the direction of attackAngle
    const attackReach = 75.0;
    const attackWidth = 60.0;

    final centerX = position.x + cos(attackAngle) * attackReach * 0.5;
    final centerY = position.y + sin(attackAngle) * attackReach * 0.5;

    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: attackWidth,
      height: attackWidth,
    );
  }

  /// Get attack damage based on combo count and upgrades
  double get attackDamage {
    final baseDamage = atk * 10 * attackMultiplier;
    final comboMult = 1.0 + (comboCount - 1) * 0.3;
    return baseDamage * comboMult;
  }

  void takeDamage(double amount, {Vector2? knockbackFrom}) {
    // Check i-frames
    if (iFrameTimer > 0 || hasIFrames) return;

    // Apply defense
    final actualDamage = amount * (1.0 - def * 0.01);
    currentHP -= actualDamage;

    if (currentHP < 0) currentHP = 0;

    // Hit effects
    isHit = true;
    hitStunTimer = 0.3;
    hitFlashTimer = 0.2;
    iFrameTimer = 1.0;

    // Knockback
    if (knockbackFrom != null) {
      final knockbackDir = (position - knockbackFrom).normalized();
      velocity.x = knockbackDir.x * 300;
      velocity.y = -200;
    }

    state = PlayerState.hit;
  }

  void heal(double amount) {
    currentHP += amount;
    if (currentHP > maxHP) currentHP = maxHP;
  }

  void addEnergy(double amount) {
    currentEnergy += amount;
    if (currentEnergy > maxEnergy) currentEnergy = maxEnergy;
  }

  bool get isDead => currentHP <= 0;
}
