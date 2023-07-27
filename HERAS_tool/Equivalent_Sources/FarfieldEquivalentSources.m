classdef (Abstract) FarfieldEquivalentSources < handle & POoperation
    % FarfieldEquivalentSources is the parent class of POSurfaceCurrents,
    % that allow to compute the farfield  sources generated by the feed 
    % after reflection on the reflector.
    % Authors : Francesco Lisi
    % Revisions : v0.1.0 - 10/02/2023

    properties
        rho_s;
        k_0, phase_yn, eta_0;
        reflector;
        feed;
        Prad;
        typeSurface = 'PEC';
        options;
        E_x_i, E_y_i, E_z_i, H_x_i, H_y_i, H_z_i; % incident fields, in the reflector CS
        E_x_r, E_y_r, E_z_r, H_x_r, H_y_r, H_z_r; % reflected fields, in the reflector CS
    end

    methods (Access = protected)
        function cp = copyElement(obj)
            % Shallow copy object
            cp = copyElement@matlab.mixin.Copyable(obj);
            % Deep copy for the reflector
            obj.reflector = obj.reflector.copy();
            % Deep copy for the feed
            obj.feed = obj.feed.copy();
        end
    end

    methods
        
        function ClearUnnecessaryFields(obj)
            % This method clears the incident and reflected fields
            obj.E_x_i=[];
            obj.E_y_i=[];
            obj.E_z_i=[];
            obj.E_x_r=[];
            obj.E_y_r=[];
            obj.E_z_r=[];
            obj.H_x_i=[];
            obj.H_y_i=[];
            obj.H_z_i=[];
            obj.H_x_r=[];
            obj.H_y_r=[];
            obj.H_z_r=[];
        end
        
        function set2PEC(obj)
            obj.typeSurface = 'PEC';
        end
        function set2Active(obj)
            obj.typeSurface = 'active';
        end
        
        
        function spillover_efficiency_dB = evaluateSpillover(obj)
            % This method computes the spillover efficiency expressed in
            % dB.

            M=1;

            % Retrieve mesh size from the mesh object
            mesh_size=size(obj.reflector.mesh.xE);

            % Store reflected electric and magnetic fields
            E_r=permute(reshape([obj.E_x_r(:).';obj.E_y_r(:).';obj.E_z_r(:).'],[3,M,mesh_size]),[1,3,4,2]);
            H_r=permute(reshape([obj.H_x_r(:).';obj.H_y_r(:).';obj.H_z_r(:).'],[3,M,mesh_size]),[1,3,4,2]);

            % Compute Poynting vector
            S_r=cross(E_r,conj(H_r))/2;
            clear E_r H_r;

            % Retrieve reflector normal on mesh
            [n_x, n_y, n_z, N] = obj.reflector.getMeshNormals('local');
            n=reshape([n_x(:).';n_y(:).';n_z(:).'],[3,mesh_size]);

            % Compute integrand
            integrand=reshape(squeeze(sum(real(S_r).*n,1)),[mesh_size,M]);
            integrand(isnan(integrand))=0;

            % Perform integral
            type = obj.reflector.mesh.intType;
            switch type
                case {'cartesian','cylindrical'}
                    [rxG,phiyG,Jacobian] = obj.reflector.getGridPoints();
                    x_sub_p_single = rxG(1,:);
                    y_sub_p_single = phiyG(:,1);
                    Prad=trapz(y_sub_p_single,trapz(x_sub_p_single,integrand.*N.*Jacobian,2));
                case 'triGauss'
                    weights = obj.reflector.mesh.weights;
                    Prad=weights.'*((W_x.*n_x+W_y.*n_y+W_z.*n_z).*N);
            end
            
            % Compute efficiency
            spillover_efficiency_dB = 10*log10(obj.feed.Prad./squeeze(Prad));
        end
    end
end