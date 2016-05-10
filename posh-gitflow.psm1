function Flow {
    param(
        [Parameter(Position=0)][string]$Category = "",
        [Parameter(Position=1)][string]$NameOrAction = "",
        [Parameter(Position=2)][string]$Action = "",
        [Parameter(Position=3)][string]$Arg1 = ""
    )

    $DefaultBranch = "master";
    $DevelopBranch = "develop";
    $FeatureBranchPrefix = "f-";
    $HotfixBranchPrefix = "h-";
	$EnvBranchPrefix = "e-";
	$Name = $NameOrAction;

    function category-develop {
		if ($Action -eq "") {
			$Action = "checkout";
		}

        if ($Action -eq "checkout") {
			git checkout $DevelopBranch

        } elseif ($Action -eq "start") {
            git checkout $DefaultBranch -b $DevelopBranch

        } elseif ($Action -eq "pull") {
            git checkout $DevelopBranch
            git rebase $DefaultBranch

        } elseif ($Action -eq "publish") {
            git checkout $DevelopBranch
            git push --set-upstream origin $DevelopBranch

        } elseif ($Action -eq "merge") {
            git checkout $DefaultBranch
	        git merge $DevelopBranch -m "[merge] $DevelopBranch"
			git checkout $DevelopBranch

        } elseif ($Action -eq "finish") {
            git checkout $DefaultBranch
	        git merge $DevelopBranch -m "[merge] $DevelopBranch"
			git checkout $DevelopBranch

        } elseif ($Action -eq "squash") {
            git checkout $DevelopBranch
            $CommonAncestor = git merge-base $DevelopBranch $DefaultBranch 
            git rebase -i $CommonAncestor

        } elseif ($Action -eq "pending" -or $Action -eq "p") {
            $Range = "$DefaultBranch..$DevelopBranch"
            Write-Host $Range
            git log --color --no-merges --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range

        } else 
        {
            Write-Host "Invalid action."
        }
    }

    function category-hotfix {
		if ($Name -eq "" -or $Name -eq "list") {
			$Branches = git branch
			$Branches | ForEach-Object { if ($_.Contains($HotfixBranchPrefix)) { Write-Host $_; } }
			return;
		}

        $HotfixBranchName = "$HotfixBranchPrefix$Name";

		function category-hotfix-finish([string]$MergeMessage) {
            git checkout $DefaultBranch
			git merge $HotfixBranchName -m $MergeMessage
            
			if ($?) {
                git checkout $DevelopBranch
				git merge $HotfixBranchName -m $MergeMessage
			}

			#$published = branch-published $DefaultBranch
			
			#if ($published) {
			#	git merge $HotfixBranchName -m $MergeMessage
			#} else {
			#	git rebase $HotfixBranchName
			#}

            #if ($?) {
			#	$published = branch-published $DevelopBranch
            #    git checkout $DevelopBranch
			#	if ($published) {
			#		git merge $HotfixBranchName -m $MergeMessage
			#	} else {
			#		git rebase $HotfixBranchName
			#	}
            #}

			#git checkout $HotfixBranchName
		}

		if ($Action -eq "") {
			$Action = "checkout";
		}

        if ($Action -eq "checkout") {
            git checkout $HotfixBranchName

        } elseif ($Action -eq "start") {
            git checkout $DefaultBranch -b $HotfixBranchName

        } elseif ($Action -eq "publish") {
            git checkout $HotfixBranchName
            git push --set-upstream origin $HotfixBranchName

        } elseif ($Action -eq "unpublish") {
            git checkout $HotfixBranchName
            git push --delete origin $HotfixBranchName

        } elseif ($Action -eq "rebase") {
            git checkout $HotfixBranchName
            git rebase $DefaultBranch

        } elseif ($Action -eq "merge") {
			category-hotfix-finish "[merge] $HotfixBranchName";
			git checkout $HotfixBranchName

        } elseif ($Action -eq "finish") {
			category-hotfix-finish "[merge] finished $HotfixBranchName";
			git checkout $DefaultBranch
            git branch -d $HotfixBranchName

        } elseif ($Action -eq "squash") {
            git checkout $HotfixBranchName
            $CommonAncestor = git merge-base $DefaultBranch $HotfixBranchName
            git rebase -i $CommonAncestor

        } elseif ($Action -eq "pending" -or $Action -eq "p") {
            $Range = "$DefaultBranch..$HotfixBranchName"
            Write-Host $Range
            git log --color --no-merges --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range

        } else 
        {
            Write-Host "Invalid action."
        }
    }

    function category-feature {
        
		if ($Action -eq "") {
			$Action = "checkout";
		}

		if ($Name -eq "" -or $Name -eq "list") {
			$Branches = git branch
			$Branches | ForEach-Object { if ($_.Contains($FeatureBranchPrefix)) { Write-Host $_; } }
			return;
		}

        $FeatureBranchName = "$FeatureBranchPrefix$Name";

        if ($Action -eq "checkout") {
            git checkout $FeatureBranchName

        } elseif ($Action -eq "start") {
            git checkout $DevelopBranch -b $FeatureBranchName

        } elseif ($Action -eq "rebase") {
            git checkout $FeatureBranchName
            git rebase $DevelopBranch

        } elseif ($Action -eq "publish") {
            git checkout $FeatureBranchName
            git push --set-upstream origin $FeatureBranchName

        } elseif ($Action -eq "unpublish") {
            git checkout $FeatureBranchName
            git push --delete origin $FeatureBranchName

        } elseif ($Action -eq "merge") {
            git checkout $DevelopBranch
	        git merge $FeatureBranchName -m "[merge] $FeatureBranchName"
			git checkout $FeatureBranchName

        } elseif ($Action -eq "finish") {
            git checkout $DevelopBranch
            git merge $FeatureBranchName -m "[merge] finished $FeatureBranchName"
            if ($?) {
                git branch -d $FeatureBranchName
            }

        } elseif ($Action -eq "squash") {
            git checkout $FeatureBranchName
            $CommonAncestor = git merge-base $DevelopBranch $FeatureBranchName
            git rebase -i $CommonAncestor

        } elseif ($Action -eq "pending" -or $Action -eq "p") {
            $Range = "$DevelopBranch..$FeatureBranchName"
            git log --color --no-merges --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range
        
        } else 
        {
            Write-Host "Invalid action."
        }
    }

    function category-environment {

        $EnvBranchName = "$EnvBranchPrefix$Name";

        if ($Action -eq "pending" -or $Action -eq "p") {

            $Source = ""            
            if ($Name -eq "hotfix") {
                $Source = $DefaultBranch;
                $EnvBranchName = "$EnvBranchPrefix$Name";
            } elseif ($Name -eq "stage") {
                $Source = $DevelopBranch;
                $EnvBranchName = "$EnvBranchPrefix$Name";
            } elseif ($Name -eq "prod") {
                $Source = $DefaultBranch
                $EnvBranchName = "$EnvBranchPrefix$Name";
            } else {
                Write-Host "Invalid Environment Name."
            }

            if ($Source -ne "") {
                $Range = "$EnvBranchName..$Source"
                Write-Host $Range
                #git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range
                git log --no-merges --color --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range
            }
        
        } elseif ($Action -eq "deploy" -or $Action -eq "d") {

            if ($Name -eq "hotfix") {
                git checkout $DefaultBranch
                git push

                git checkout $EnvBranchName
                git merge $DefaultBranch --no-ff -m "[merge] deploy $Name"
                if ($?) {
                    git push
                    git checkout $Source
                }

                git checkout $DefaultBranch
                
            } elseif ($Name -eq "stage") {
                git checkout $DevelopBranch
                git push

                git checkout $EnvBranchName
                git merge $DevelopBranch --no-ff -m "[merge] deploy $Name"
                if ($?) {
                    git push
                }

                git checkout $DevelopBranch

            } elseif ($Name -eq "prod") {
                git checkout $DefaultBranch
                git push

                git checkout $EnvBranchName
                git merge $DefaultBranch --no-ff -m "[merge] deploy $Name"
                if ($?) {
                    git push
                }

                git checkout $DefaultBranch

            } else {
                Write-Host "Invalid name."
            }

		# } elseif ($Action -eq "swap") {

        #     if ($Name -eq "prod") {
		# 		git checkout $EnvBranchName

		# 		Write-Host ""
		# 		$response = Read-Host -Prompt "Migrate prod database? [y/n/abort]"

		# 		if ($response -eq "abort") {
		# 			return;
		# 		}
				
		# 		if ($response -eq "y") {
		# 			msbuild "c:\source\vega\vega.sln"
		# 			vega migrate -e prod
		# 		}
	
		# 		if ($Arg1 -eq "") {
		# 			$Arg1 = "hotfix";
		# 		}

		# 		azure site swap Scout20 production $Arg1
		# 	}

        } elseif ($Action -eq "") {
            git checkout $Name
        }       
    }
    
	function category-push {
		git push origin $DefaultBranch
		git push origin $DevelopBranch
	}

	function branch-published([string]$BranchName) {
		#$Ret = git ls-remote --heads origin $BranchName
		$Range = "origin/$BranchName..$BranchName"
		$Ret = git log --oneline $Range
		$Ret = [string]::IsNullOrEmpty($Ret)
		return $Ret;
	}

	$DevelopCategories = @($DevelopBranch, "develop", "dev", "d");
	$HotfixCategories = @("hotfix", "fx", "h");
	$FeatureCategories = @("feature", "f");
	$PushCategories = @("push", "p");
	$EnvCategories = @("environment", "env", "e");

    if ($DevelopCategories -contains $Category) { 
		$Action = $NameOrAction;
        category-develop; 
    } elseif ($HotfixCategories -contains $Category) {
        category-hotfix; 
	} elseif ($FeatureCategories -contains $Category) {
        category-feature; 
	} elseif ($PushCategories -contains $Category) {
        category-push; 
	} elseif ($EnvCategories -contains $Category) {
        category-environment;
	} elseif ($Category -eq "") {
		git branch
    } else {
        Write-Host "Invalid category."
    }
}

Export-ModuleMember -Function @( 'Flow' )

Write-Host "posh-gitflow ready." -ForegroundColor Green

