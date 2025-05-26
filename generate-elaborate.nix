{

  /*
    Given a platform triple (build,run,target), this function generates the
    necessary fixpoint links to recursively construct the elaborated set of
    packages to use elsewhere.

    It automatically minimizes the requested amount of evaluation if the build,
    run or target platforms coincide.
    Technically speaking, these reductions are not necessary. But for the
    efficiency of the implementation, a let-in construct is used to help the
    evaluator reduce duplications of the same fixpoint.

    # Input
    `platforms`: specific platforms requested to build for.

    # Type
    generateBootstrapFunction :: Attrset -> (Attrset -> Attrset)

   */
  generateBootstrapFunction = platforms: let
    build = platforms.buildPlatform;
    run = platforms.runPlatform;
    target = platforms.targetPlatform;

    singlePlatform = self: let
      output = {
        triple = { inherit (platforms) buildPlatform runPlatform targetPlatform; };
        adjacent = { inherit (self) pkgsBuildBuild pkgsBuildRun pkgsBuildTarget pkgsRunRun pkgsRunTarget pkgsTargetTarget; };
      };
    in {
      pkgsBuildBuild = output;
      pkgsBuildRun = output;
      pkgsBuildTarget = output;
      pkgsRunRun = output;
      pkgsRunTarget = output;
      pkgsTargetTarget = output;
    };

    buildIsRun = self: let
      buildBuild = {
        triple = {
          inherit (platforms) buildPlatform runPlatform;
          targetPlatform = platforms.buildPlatform;
        };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildBuild;
          pkgsBuildTarget = self.pkgsBuildBuild;
          pkgsRunRun = self.pkgsBuildBuild;
          pkgsRunTarget = self.pkgsBuildBuild;
          pkgsTargetTarget = self.pkgsBuildBuild;
        };
      };
      buildTarget = {
        triple = { inherit (platforms) buildPlatform runPlatform targetPlatform; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildBuild;
          pkgsBuildTarget = self.pkgsBuildTarget;
          pkgsRunRun = self.pkgsBuildBuild;
          pkgsRunTarget = self.pkgsBuildTarget;
          pkgsTargetTarget = self.pkgsTargetTarget;
        };
      };
      targetTarget = {
        triple = {
          inherit (platforms) buildPlatform;
          runPlatform = platforms.targetPlatform;
          targetPlatform = platforms.targetPlatform;
        };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildTarget;
          pkgsBuildTarget = self.pkgsBuildTarget;
          pkgsRunRun = self.pkgsTargetTarget;
          pkgsRunTarget = self.pkgsTargetTarget;
          pkgsTargetTarget = self.pkgsTargetTarget;
        };
      };
    in {
      pkgsBuildBuild = buildBuild;
      pkgsBuildRun = buildBuild;
      pkgsBuildTarget = buildTarget;
      pkgsRunRun = buildBuild;
      pkgsRunTarget = buildTarget;
      pkgsTargetTarget = targetTarget;
    };

    runIsTarget = self: let
      buildBuild = {
        triple = {
          inherit (platforms) buildPlatform;
          runPlatform = platforms.buildPlatform;
          targetPlatform = platforms.buildPlatform;
        };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildBuild;
          pkgsBuildTarget = self.pkgsBuildBuild;
          pkgsRunRun = self.pkgsBuildBuild;
          pkgsRunTarget = self.pkgsBuildBuild;
          pkgsTargetTarget = self.pkgsBuildBuild;
        };
      };
      buildRun = {
        triple = {
          inherit (platforms) buildPlatform targetPlatform;
          runPlatform = platforms.buildPlatform;
        };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildBuild;
          pkgsBuildTarget = self.pkgsBuildRun;
          pkgsRunRun = self.pkgsBuildBuild;
          pkgsRunTarget = self.pkgsBuildRun;
          pkgsTargetTarget = self.pkgsRunRun;
        };
      };
      runRun = {
        triple = { inherit (platforms) buildPlatform runPlatform targetPlatform; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildRun;
          pkgsBuildTarget = self.pkgsBuildRun;
          pkgsRunRun = self.pkgsRunRun;
          pkgsRunTarget = self.pkgsRunRun;
          pkgsTargetTarget = self.pkgsRunRun;
        };
      };
    in {
      pkgsBuildBuild = buildBuild;
      pkgsBuildRun = buildRun;
      pkgsBuildTarget = buildRun;
      pkgsRunRun = runRun;
      pkgsRunTarget = runRun;
      pkgsTargetTarget = runRun;
    };

    canadian = self: {
      pkgsBuildBuild = {
        triple = { buildPlatform = build; runPlatform = build; targetPlatform = build; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildBuild;
          pkgsBuildTarget = self.pkgsBuildBuild;
          pkgsRunRun = self.pkgsBuildBuild;
          pkgsRunTarget = self.pkgsBuildBuild;
          pkgsTargetTarget = self.pkgsBuildBuild;
        };
      };
      pkgsBuildRun = {
        triple = { buildPlatform = build; runPlatform = build; targetPlatform = run; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildBuild;
          pkgsBuildTarget = self.pkgsBuildRun;
          pkgsRunRun = self.pkgsBuildBuild;
          pkgsRunTarget = self.pkgsBuildRun;
          pkgsTargetTarget = self.pkgsRunRun;
        };
      };
      pkgsBuildTarget = {
        triple = { buildPlatform = build; runPlatform = build; targetPlatform = target; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildBuild;
          pkgsBuildTarget = self.BuildTarget;
          pkgsRunRun = self.pkgsBuildBuild;
          pkgsRunTarget = self.pkgsBuildTarget;
          pkgsTargetTarget = self.pkgsTargetTarget;
        };
      };
      pkgsRunRun = {
        triple = { buildPlatform = build; runPlatform = run; targetPlatform = run; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildRun;
          pkgsBuildTarget = self.pkgsBuildRun;
          pkgsRunRun = self.pkgsRunRun;
          pkgsRunTarget = self.pkgsRunRun;
          pkgsTargetTarget = self.pkgsRunRun;
        };
      };
      pkgsRunTarget = {
        triple = { buildPlatform = build; runPlatform = run; targetPlatform = target; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildRun;
          pkgsBuildTarget = self.pkgsBuildTarget;
          pkgsRunRun = self.pkgsRunRun;
          pkgsRunTarget = self.pkgsRunTarget;
          pkgsTargetTarget = self.pkgsTargetTarget;
        };
      };
      pkgsTargetTarget = {
        triple = { buildPlatform = build; runPlatform = target; targetPlatform = target; };
        adjacent = {
          pkgsBuildBuild = self.pkgsBuildBuild;
          pkgsBuildRun = self.pkgsBuildTarget;
          pkgsBuildTarget = self.pkgsBuildTarget;
          pkgsRunRun = self.pkgsTargetTarget;
          pkgsRunTarget = self.pkgsTargetTarget;
          pkgsTargetTarget = self.pkgsTargetTarget;
        };
      };
    };

  in (if (build == run && run == target) then singlePlatform
    else if (build == run) then buildIsRun
    else if (run == target) then runIsTarget
    else canadian
  );

}
